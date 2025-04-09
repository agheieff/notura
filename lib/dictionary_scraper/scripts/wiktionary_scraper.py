#!/usr/bin/env python3
"""
Wiktionary Scraper - Extract dictionary data from Wiktionary pages

This script scrapes word data from Wiktionary pages and saves it in JSON format
compatible with the Notura dictionary system.
"""

import argparse
import json
import os
import re
import time
from typing import Dict, List, Any, Optional
from urllib.parse import quote

from bs4 import BeautifulSoup

# Import the curl wrapper for HTTP requests
from wiktionary_curl_wrapper import WiktionaryCurlWrapper


class WiktionaryScraper:
    """Scraper for extracting word data from Wiktionary pages."""

    def __init__(self, lang_code="es", output_dir="data", rate_limit=1.0):
        """Initialize the scraper.
        
        Args:
            lang_code: The language code to scrape (e.g., "es" for Spanish)
            output_dir: Directory to save scraped data
            rate_limit: Time in seconds to wait between requests
        """
        self.lang_code = lang_code
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            output_dir
        )
        self.rate_limit = rate_limit
        
        # Initialize the curl wrapper
        self.curl_wrapper = WiktionaryCurlWrapper(rate_limit=rate_limit)
        
        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Language-specific settings
        self.language_name = self._get_language_name(lang_code)
    
    def _get_language_name(self, lang_code: str) -> str:
        """Get full language name from code."""
        language_map = {
            "es": "Spanish",
            "en": "English",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "la": "Latin",
        }
        return language_map.get(lang_code, lang_code.upper())
    
    def scrape_word(self, word: str) -> Dict[str, Any]:
        """Scrape data for a specific word.
        
        Args:
            word: The word to scrape
            
        Returns:
            A dictionary containing the scraped word data
        """
        print(f"Scraping '{word}'...")
        
        # Fetch the page content using curl
        html_content = self.curl_wrapper.fetch_page(word)
        if not html_content:
            print(f"Failed to retrieve page for '{word}'")
            return {}
        
        soup = BeautifulSoup(html_content, "html.parser")
        
        # Find the language section
        lang_section = None
        for h2 in soup.find_all("h2"):
            if h2.find("span", {"class": "mw-headline"}) and \
               h2.find("span", {"class": "mw-headline"}).text == self.language_name:
                lang_section = h2
                break
        
        if not lang_section:
            print(f"No {self.language_name} section found for {word}")
            return {}
        
        # Get all content in this language section (until the next h2)
        lang_content = []
        current = lang_section.next_sibling
        while current and not (current.name == "h2"):
            if current.name:
                lang_content.append(current)
            current = current.next_sibling
        
        # Build the word data
        word_data = {
            "text": word,
            "language_code": self.lang_code,
            "translations": self._extract_translations(lang_content),
            "ipa_transcriptions": self._extract_pronunciations(lang_content),
            "definitions": self._extract_definitions(lang_content),
            "examples": self._extract_examples(lang_content),
            "word_class": self._extract_word_class(lang_content),
            "word_forms": self._extract_word_forms(lang_content, word),
            "synonyms": self._extract_synonyms(lang_content),
            "antonyms": self._extract_antonyms(lang_content),
            "etymology": self._extract_etymology(lang_content),
            "related_words": self._extract_related_words(lang_content),
            "tags": self._extract_tags(lang_content),
        }
        
        return word_data
    
    def _extract_word_class(self, content) -> str:
        """Extract word class (part of speech) from the content."""
        for elem in content:
            if elem.name == "h3":
                pos_span = elem.find("span", {"class": "mw-headline"})
                if pos_span:
                    pos_text = pos_span.text.lower()
                    # Map Wiktionary part of speech to our standardized categories
                    pos_mapping = {
                        "noun": "noun",
                        "verb": "verb",
                        "adjective": "adjective",
                        "adverb": "adverb",
                        "pronoun": "pronoun",
                        "preposition": "preposition",
                        "conjunction": "conjunction",
                        "interjection": "interjection",
                        "article": "article",
                        "numeral": "numeral",
                    }
                    for wikt_pos, standard_pos in pos_mapping.items():
                        if wikt_pos in pos_text:
                            return standard_pos
        return "unknown"
    
    def _extract_pronunciations(self, content) -> List[str]:
        """Extract IPA transcriptions from the content."""
        ipa_list = []
        for elem in content:
            if elem.name == "h3" and elem.find("span", {"class": "mw-headline"}, text="Pronunciation"):
                # Find the next <ul> element
                current = elem.next_sibling
                while current and current.name != "ul":
                    current = current.next_sibling
                
                if current and current.name == "ul":
                    for li in current.find_all("li"):
                        # Look for IPA notation
                        ipa_span = li.find("span", {"class": "IPA"})
                        if ipa_span:
                            ipa_text = ipa_span.text.strip()
                            # Remove brackets if present
                            ipa_text = re.sub(r'[/\[\]]', '', ipa_text)
                            ipa_list.append(ipa_text)
        
        return ipa_list
    
    def _extract_definitions(self, content) -> List[str]:
        """Extract definitions from the content."""
        definitions = []
        current_pos = None
        
        for elem in content:
            # Track current part of speech
            if elem.name == "h3" or elem.name == "h4":
                pos_span = elem.find("span", {"class": "mw-headline"})
                if pos_span and not pos_span.text.lower() in ["pronunciation", "etymology"]:
                    current_pos = pos_span.text.lower()
            
            # Look for definition lists
            if elem.name == "ol" and current_pos:
                for li in elem.find_all("li", recursive=False):
                    # Skip examples and other non-definition content
                    if li.find("dl") or li.find("ul"):
                        continue
                    
                    definition_text = li.get_text().strip()
                    # Clean up some common formatting issues
                    definition_text = re.sub(r'\([^)]*\)', '', definition_text)  # Remove parenthetical text
                    definition_text = re.sub(r'\s+', ' ', definition_text)  # Normalize whitespace
                    
                    if definition_text:
                        definitions.append(definition_text)
        
        return definitions
    
    def _extract_examples(self, content) -> List[str]:
        """Extract example sentences from the content."""
        examples = []
        
        for elem in content:
            # Look for example lists (usually in a <dl> after a definition)
            if elem.name == "ol":
                for li in elem.find_all("li", recursive=False):
                    example_dl = li.find("dl")
                    if example_dl:
                        for dd in example_dl.find_all("dd"):
                            example_text = dd.get_text().strip()
                            if example_text:
                                # Clean up formatting
                                example_text = re.sub(r'\s+', ' ', example_text)
                                examples.append(example_text)
            
            # Sometimes examples are in <ul> with class "citations"
            if elem.name == "ul" and "citations" in elem.get("class", []):
                for li in elem.find_all("li"):
                    example_text = li.get_text().strip()
                    if example_text:
                        examples.append(example_text)
        
        return examples
    
    def _extract_translations(self, content) -> Dict[str, List[str]]:
        """Extract translations from the content."""
        translations = {}
        
        for elem in content:
            if elem.name == "h4" and elem.find("span", {"class": "mw-headline"}, text="Translations"):
                # Find the translation tables
                current = elem.next_sibling
                while current and not (current.name == "h3" or current.name == "h4"):
                    if current.name == "div" and "translations" in current.get("class", []):
                        for li in current.find_all("li"):
                            # Each li usually has language name followed by translation
                            lang_link = li.find("a", {"class": "language"})
                            if lang_link:
                                lang_name = lang_link.text.strip()
                                lang_code = self._get_language_code(lang_name)
                                if lang_code:
                                    # Get all translations for this language
                                    trans_spans = li.find_all("span", {"lang": True})
                                    if trans_spans:
                                        translations[lang_code] = [span.text.strip() for span in trans_spans]
                    
                    current = current.next_sibling
        
        return translations
    
    def _get_language_code(self, language_name: str) -> Optional[str]:
        """Convert a language name to a language code."""
        language_map = {
            "English": "en",
            "Spanish": "es",
            "French": "fr",
            "German": "de",
            "Italian": "it",
            "Portuguese": "pt",
            "Latin": "la",
            # Add more mappings as needed
        }
        return language_map.get(language_name)
    
    def _extract_word_forms(self, content, base_word: str) -> Dict[str, Any]:
        """Extract word forms from the content."""
        word_forms = {}
        
        # For Spanish verbs
        if self.lang_code == "es":
            # Look for conjugation tables
            for elem in content:
                if elem.name == "table" and "conjugation" in elem.get("class", []):
                    # Process Spanish verb conjugation table
                    word_forms = self._process_spanish_verb_conjugation(elem)
                
                # Look for anchored conjugation tables as well
                if elem.name == "div" and "inflection-table" in elem.get("class", []):
                    tables = elem.find_all("table")
                    for table in tables:
                        if "conjugation" in table.get("class", []):
                            forms = self._process_spanish_verb_conjugation(table)
                            # Merge with existing forms
                            for mood, tenses in forms.items():
                                if mood not in word_forms:
                                    word_forms[mood] = {}
                                for tense, persons in tenses.items():
                                    word_forms[mood][tense] = persons
        
        return word_forms
    
    def _process_spanish_verb_conjugation(self, table) -> Dict[str, Any]:
        """Process a Spanish verb conjugation table."""
        conjugation = {}
        current_mood = None
        current_tense = None
        
        # First check if this is a conjugation table with headers
        headers = table.find_all("th")
        if not headers:
            return conjugation
        
        # Process headers to identify moods and tenses
        for header in headers:
            header_text = header.text.strip().lower()
            
            # Identify moods
            for mood in ["indicative", "subjunctive", "imperative", "conditional"]:
                if mood in header_text:
                    current_mood = mood
                    conjugation[current_mood] = {}
                    break
            
            # Identify tenses for current mood
            if current_mood and any(tense in header_text for tense in 
                                   ["present", "preterite", "imperfect", "future", "conditional"]):
                # Simplify and standardize tense names
                if "present" in header_text:
                    current_tense = "present"
                elif "preterite" in header_text or "past" in header_text:
                    current_tense = "preterite"
                elif "imperfect" in header_text:
                    current_tense = "imperfect"
                elif "future" in header_text:
                    current_tense = "future"
                elif "conditional" in header_text:
                    current_tense = "conditional"
                
                if current_tense:
                    conjugation[current_mood][current_tense] = {}
        
        # Process the table cells to extract conjugations
        rows = table.find_all("tr")
        for row in rows:
            cells = row.find_all(["th", "td"])
            if len(cells) < 2:
                continue
            
            # First cell might have person info
            person_cell = cells[0].text.strip().lower()
            
            # Map to standard person keys
            person_key = None
            if any(p in person_cell for p in ["yo", "i", "1s"]):
                person_key = "1sg"
            elif any(p in person_cell for p in ["tú", "you", "2s"]):
                person_key = "2sg"
            elif any(p in person_cell for p in ["él", "usted", "he", "she", "it", "3s"]):
                person_key = "3sg"
            elif any(p in person_cell for p in ["nosotros", "we", "1p"]):
                person_key = "1pl"
            elif any(p in person_cell for p in ["vosotros", "you all", "2p"]):
                person_key = "2pl"
            elif any(p in person_cell for p in ["ellos", "ustedes", "they", "3p"]):
                person_key = "3pl"
            
            # If we have a person and a current mood and tense
            if person_key and current_mood and current_tense:
                # Second cell has the conjugated form
                form = cells[1].text.strip()
                if form:
                    conjugation[current_mood][current_tense][person_key] = form
        
        return conjugation
    
    def _extract_synonyms(self, content) -> List[str]:
        """Extract synonyms from the content."""
        synonyms = []
        for elem in content:
            if elem.name == "h4" and elem.find("span", {"class": "mw-headline"}, text="Synonyms"):
                # Find the next <ul> element
                current = elem.next_sibling
                while current and current.name != "ul":
                    current = current.next_sibling
                
                if current and current.name == "ul":
                    for li in current.find_all("li"):
                        for link in li.find_all("a"):
                            synonym = link.text.strip()
                            if synonym and not synonym.startswith("Thesaurus:"):
                                synonyms.append(synonym)
        
        return synonyms
    
    def _extract_antonyms(self, content) -> List[str]:
        """Extract antonyms from the content."""
        antonyms = []
        for elem in content:
            if elem.name == "h4" and elem.find("span", {"class": "mw-headline"}, text="Antonyms"):
                # Find the next <ul> element
                current = elem.next_sibling
                while current and current.name != "ul":
                    current = current.next_sibling
                
                if current and current.name == "ul":
                    for li in current.find_all("li"):
                        for link in li.find_all("a"):
                            antonym = link.text.strip()
                            if antonym:
                                antonyms.append(antonym)
        
        return antonyms
    
    def _extract_etymology(self, content) -> Optional[str]:
        """Extract etymology information from the content."""
        for elem in content:
            if elem.name == "h3" and elem.find("span", {"class": "mw-headline"}, text="Etymology"):
                # Find the next <p> element
                current = elem.next_sibling
                while current and current.name != "p":
                    current = current.next_sibling
                
                if current and current.name == "p":
                    etymology = current.get_text().strip()
                    # Clean up formatting
                    etymology = re.sub(r'\s+', ' ', etymology)
                    return etymology
        
        return None
    
    def _extract_related_words(self, content) -> List[str]:
        """Extract related words (derived terms, etc.) from the content."""
        related = []
        for elem in content:
            if elem.name == "h4" and elem.find("span", {"class": "mw-headline"}) and \
               any(t in elem.text.lower() for t in ["derived terms", "related terms"]):
                # Find the next <ul> element
                current = elem.next_sibling
                while current and current.name != "ul":
                    current = current.next_sibling
                
                if current and current.name == "ul":
                    for li in current.find_all("li"):
                        for link in li.find_all("a"):
                            related_word = link.text.strip()
                            if related_word:
                                related.append(related_word)
        
        return related
    
    def _extract_tags(self, content) -> List[str]:
        """Extract tags (usage, regional, etc.) from the content."""
        tags = []
        
        # Look for usage notes
        for elem in content:
            if elem.name == "h4" and elem.find("span", {"class": "mw-headline"}, text="Usage notes"):
                # Extract context labels
                current = elem.next_sibling
                while current and not (current.name in ["h3", "h4"]):
                    if current.name == "p":
                        text = current.get_text().lower()
                        for tag in ["formal", "informal", "colloquial", "slang", "archaic", "literary", 
                                   "regional", "technical", "vulgar", "offensive"]:
                            if tag in text:
                                tags.append(tag)
                    current = current.next_sibling
        
        # Look for context labels in definitions
        for elem in content:
            if elem.name == "ol":  # Definition lists
                for li in elem.find_all("li"):
                    text = li.get_text().lower()
                    for tag in ["formal", "informal", "colloquial", "slang", "archaic", "literary", 
                               "regional", "technical", "vulgar", "offensive"]:
                        if f"({tag})" in text:
                            tags.append(tag)
        
        return list(set(tags))  # Remove duplicates
    
    def scrape_word_list(self, word_list_file: str, output_file: Optional[str] = None):
        """Scrape data for a list of words from a file.
        
        Args:
            word_list_file: Path to the file containing words to scrape (one per line)
            output_file: Path to save the scraped data (JSON format)
        """
        if not os.path.exists(word_list_file):
            print(f"Word list file not found: {word_list_file}")
            return
        
        with open(word_list_file, "r", encoding="utf-8") as f:
            words = [line.strip() for line in f if line.strip()]
        
        output_file = output_file or os.path.join(
            self.output_dir, 
            f"wiktionary_{self.lang_code}_{len(words)}_words.json"
        )
        
        print(f"Scraping {len(words)} words from Wiktionary ({self.language_name})...")
        
        results = {}
        for i, word in enumerate(words):
            try:
                print(f"[{i+1}/{len(words)}] Scraping '{word}'...")
                word_data = self.scrape_word(word)
                if word_data:
                    results[word] = word_data
            
            except Exception as e:
                print(f"Error scraping '{word}': {str(e)}")
        
        # Save results
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        
        print(f"Scraped {len(results)} words. Data saved to {output_file}")
        return output_file
    
    def scrape_frequency_list(self, count: int = 1000, output_file: Optional[str] = None):
        """Scrape the most common words in the language.
        
        Args:
            count: Number of words to scrape
            output_file: Path to save the scraped data (JSON format)
        """
        # This would normally fetch a frequency list from somewhere
        # For this example, we'll just use a small hardcoded list for Spanish
        if self.lang_code == "es":
            common_spanish_words = [
                "ser", "estar", "tener", "hacer", "poder", "decir", "ir", "ver", "dar", "saber",
                "querer", "llegar", "pasar", "deber", "poner", "parecer", "quedar", "creer", "hablar", "llevar",
                # Add more words here...
            ]
            
            # Create a temporary file with these words
            temp_file = os.path.join(self.output_dir, f"temp_{self.lang_code}_common_words.txt")
            with open(temp_file, "w", encoding="utf-8") as f:
                for word in common_spanish_words[:count]:
                    f.write(f"{word}\n")
            
            # Scrape these words
            result = self.scrape_word_list(temp_file, output_file)
            
            # Clean up temporary file
            os.remove(temp_file)
            
            return result
        else:
            print(f"Frequency list not implemented for {self.language_name}")
            return None


def main():
    """Main function to run the scraper from command line."""
    parser = argparse.ArgumentParser(description="Scrape word data from Wiktionary")
    
    parser.add_argument("--lang", type=str, default="es", help="Language code to scrape (default: es)")
    parser.add_argument("--word", type=str, help="Single word to scrape")
    parser.add_argument("--word-list", type=str, help="File with words to scrape (one per line)")
    parser.add_argument("--frequency", type=int, help="Scrape top N most frequent words")
    parser.add_argument("--output", type=str, help="Output file path (default: auto-generated)")
    parser.add_argument("--rate-limit", type=float, default=1.0, 
                        help="Seconds to wait between requests (default: 1.0)")
    
    args = parser.parse_args()
    
    scraper = WiktionaryScraper(lang_code=args.lang, rate_limit=args.rate_limit)
    
    if args.word:
        # Scrape a single word
        word_data = scraper.scrape_word(args.word)
        if word_data:
            output_file = args.output or os.path.join(
                scraper.output_dir, 
                f"wiktionary_{args.lang}_{args.word}.json"
            )
            with open(output_file, "w", encoding="utf-8") as f:
                json.dump({args.word: word_data}, f, ensure_ascii=False, indent=2)
            print(f"Data saved to {output_file}")
        else:
            print(f"No data found for '{args.word}'")
    
    elif args.word_list:
        # Scrape a list of words
        scraper.scrape_word_list(args.word_list, args.output)
    
    elif args.frequency:
        # Scrape frequent words
        scraper.scrape_frequency_list(args.frequency, args.output)
    
    else:
        print("Please specify --word, --word-list, or --frequency")


if __name__ == "__main__":
    main()