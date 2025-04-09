#!/usr/bin/env python3
"""
Frequency List Scraper - Download and process frequency lists for different languages.

This script can fetch frequency lists from various sources and prepare them
for processing by the Wiktionary scraper.
"""

import argparse
import csv
import gzip
import json
import os
import re
import requests
import zipfile
from typing import List, Dict, Optional, Tuple

class FrequencyListScraper:
    """Scraper for obtaining word frequency lists for different languages."""

    def __init__(self, output_dir="data"):
        """Initialize the scraper.
        
        Args:
            output_dir: Directory to save downloaded lists
        """
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            output_dir
        )
        
        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Known sources of frequency lists by language
        self.frequency_sources = {
            "es": [
                {
                    "name": "Subtlex-ESP",
                    "url": "https://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexesp/subtlexesp.zip",
                    "file_in_archive": "SubtlexESP.txt", 
                    "format": "csv",
                    "word_column": "Word", 
                    "frequency_column": "FreqCount"
                },
                {
                    "name": "RAE Frequency Dictionary",
                    "url": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/es/es_50k.txt",
                    "format": "line",
                    "pattern": r"^(\S+) (\d+)$"  # Word followed by frequency count
                }
            ],
            "en": [
                {
                    "name": "COCA Frequency List",
                    "url": "https://www.wordfrequency.info/samples/lemmas_60k.zip",  # Sample URL, actual requires login
                    "file_in_archive": "lemmas_60k.txt",
                    "format": "csv",
                    "word_column": 1,
                    "frequency_column": 2
                }
            ],
            "fr": [
                {
                    "name": "Lexique",
                    "url": "http://www.lexique.org/databases/Lexique383/Lexique383.tsv", 
                    "format": "tsv",
                    "word_column": "ortho", 
                    "frequency_column": "freqlivres"
                }
            ],
            # Add more language sources as needed
        }
    
    def download_file(self, url: str, target_path: str) -> bool:
        """Download a file from a URL.
        
        Args:
            url: The URL to download from
            target_path: Where to save the downloaded file
            
        Returns:
            True if successful, False otherwise
        """
        try:
            print(f"Downloading {url}...")
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            with open(target_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            print(f"Downloaded to {target_path}")
            return True
        
        except Exception as e:
            print(f"Error downloading {url}: {str(e)}")
            return False
    
    def extract_archive(self, archive_path: str, extract_to: str) -> Optional[List[str]]:
        """Extract files from a zip archive.
        
        Args:
            archive_path: Path to the archive file
            extract_to: Directory to extract to
            
        Returns:
            List of extracted file paths or None if failed
        """
        try:
            if archive_path.endswith('.zip'):
                with zipfile.ZipFile(archive_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_to)
                    return [os.path.join(extract_to, name) for name in zip_ref.namelist()]
            
            elif archive_path.endswith('.gz'):
                # For gzip files (usually single file archives)
                output_path = os.path.join(extract_to, os.path.basename(archive_path)[:-3])
                with gzip.open(archive_path, 'rb') as f_in:
                    with open(output_path, 'wb') as f_out:
                        f_out.write(f_in.read())
                return [output_path]
            
            else:
                print(f"Unsupported archive format: {archive_path}")
                return None
        
        except Exception as e:
            print(f"Error extracting {archive_path}: {str(e)}")
            return None
    
    def process_csv_file(self, file_path: str, word_column: str, frequency_column: str, 
                         delimiter: str = ',') -> List[Tuple[str, int]]:
        """Process a CSV file to extract words and their frequencies.
        
        Args:
            file_path: Path to the CSV file
            word_column: Column name or index for the word
            frequency_column: Column name or index for the frequency
            delimiter: CSV delimiter character
            
        Returns:
            List of (word, frequency) tuples
        """
        try:
            words = []
            
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                # Try to determine if the file has headers
                sample = f.read(1024)
                f.seek(0)
                
                has_header = csv.Sniffer().has_header(sample)
                reader = csv.reader(f, delimiter=delimiter)
                
                if has_header:
                    headers = next(reader)
                    # Convert column names to indices if needed
                    if isinstance(word_column, str):
                        word_column = headers.index(word_column)
                    if isinstance(frequency_column, str):
                        frequency_column = headers.index(frequency_column)
                
                for row in reader:
                    if len(row) > max(word_column, frequency_column):
                        word = row[word_column].strip().lower()
                        try:
                            freq = int(float(row[frequency_column]))
                            if word and freq > 0 and re.match(r'^[a-záéíóúüñ]+$', word):
                                words.append((word, freq))
                        except ValueError:
                            # Skip rows with non-numeric frequency
                            continue
            
            return words
        
        except Exception as e:
            print(f"Error processing CSV {file_path}: {str(e)}")
            return []
    
    def process_tsv_file(self, file_path: str, word_column: str, frequency_column: str) -> List[Tuple[str, int]]:
        """Process a TSV file to extract words and their frequencies."""
        return self.process_csv_file(file_path, word_column, frequency_column, delimiter='\t')
    
    def process_line_file(self, file_path: str, pattern: str) -> List[Tuple[str, int]]:
        """Process a simple line-based frequency list.
        
        Args:
            file_path: Path to the text file
            pattern: Regex pattern with two capture groups (word and frequency)
            
        Returns:
            List of (word, frequency) tuples
        """
        try:
            words = []
            
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                for line in f:
                    line = line.strip()
                    match = re.match(pattern, line)
                    if match:
                        word, freq_str = match.groups()
                        word = word.strip().lower()
                        try:
                            freq = int(float(freq_str))
                            if word and freq > 0 and re.match(r'^[a-záéíóúüñ]+$', word):
                                words.append((word, freq))
                        except ValueError:
                            continue
            
            return words
        
        except Exception as e:
            print(f"Error processing line file {file_path}: {str(e)}")
            return []
    
    def get_frequency_list(self, lang_code: str, limit: int = 5000, 
                           source_index: int = 0) -> List[str]:
        """Get a frequency list for a specific language.
        
        Args:
            lang_code: Language code (e.g., "es" for Spanish)
            limit: Maximum number of words to include
            source_index: Which source to use if multiple are available
            
        Returns:
            List of words ordered by frequency
        """
        if lang_code not in self.frequency_sources:
            print(f"No frequency sources defined for language code '{lang_code}'")
            return []
        
        if source_index >= len(self.frequency_sources[lang_code]):
            print(f"Invalid source index {source_index} for language code '{lang_code}'")
            return []
        
        source = self.frequency_sources[lang_code][source_index]
        source_name = source["name"]
        
        # Create language-specific directory
        lang_dir = os.path.join(self.output_dir, lang_code)
        os.makedirs(lang_dir, exist_ok=True)
        
        # Download the frequency list if needed
        url = source["url"]
        filename = os.path.basename(url)
        download_path = os.path.join(lang_dir, filename)
        
        if not os.path.exists(download_path):
            if not self.download_file(url, download_path):
                return []
        
        # Extract if it's an archive
        extracted_files = None
        if filename.endswith(('.zip', '.gz')):
            extracted_files = self.extract_archive(download_path, lang_dir)
            if not extracted_files:
                return []
            
            # Find the specific file we want from the archive
            if "file_in_archive" in source:
                target_file = None
                for extracted_file in extracted_files:
                    if os.path.basename(extracted_file) == source["file_in_archive"]:
                        target_file = extracted_file
                        break
                
                if not target_file:
                    print(f"Could not find {source['file_in_archive']} in extracted files")
                    return []
            else:
                # Just use the first file
                target_file = extracted_files[0]
        else:
            # Direct file download, not an archive
            target_file = download_path
        
        # Process the file based on its format
        words_with_freq = []
        
        if source["format"] == "csv":
            words_with_freq = self.process_csv_file(
                target_file, source["word_column"], source["frequency_column"]
            )
        
        elif source["format"] == "tsv":
            words_with_freq = self.process_tsv_file(
                target_file, source["word_column"], source["frequency_column"]
            )
        
        elif source["format"] == "line":
            words_with_freq = self.process_line_file(
                target_file, source["pattern"]
            )
        
        # Sort by frequency (highest first) and take top words
        words_with_freq.sort(key=lambda x: x[1], reverse=True)
        top_words = [word for word, _ in words_with_freq[:limit]]
        
        # Save the processed list
        output_path = os.path.join(lang_dir, f"{lang_code}_top_{limit}_{source_name.lower().replace(' ', '_')}.txt")
        with open(output_path, 'w', encoding='utf-8') as f:
            for word in top_words:
                f.write(f"{word}\n")
        
        print(f"Saved {len(top_words)} words to {output_path}")
        return top_words
    
    def filter_by_word_class(self, lang_code: str, words: List[str], 
                             target_class: str, limit: int = 1000) -> List[str]:
        """Filter a list of words to keep only those matching a specific word class.
        
        This requires some language-specific logic or API calls to determine word classes.
        
        Args:
            lang_code: Language code
            words: List of words to filter
            target_class: Target word class (e.g., "verb", "noun")
            limit: Maximum number of words to return
            
        Returns:
            Filtered list of words
        """
        # For Spanish, we can use some heuristics for verbs
        if lang_code == "es" and target_class == "verb":
            verb_endings = ("ar", "er", "ir")
            verbs = [w for w in words if w.endswith(verb_endings)]
            return verbs[:limit]
        
        # Otherwise we would need to use a POS tagger or dictionary API
        print(f"Warning: Filtering by word class not fully implemented for {lang_code}/{target_class}")
        return words[:limit]
    
    def generate_complete_wordlist(self, lang_code: str, output_file: Optional[str] = None) -> str:
        """Generate a comprehensive wordlist for a language combining multiple sources.
        
        Args:
            lang_code: Language code to process
            output_file: Optional custom output file path
            
        Returns:
            Path to the generated wordlist file
        """
        if lang_code not in self.frequency_sources:
            print(f"No frequency sources defined for language code '{lang_code}'")
            return ""
        
        all_words = set()
        
        # Process all available sources for this language
        for i in range(len(self.frequency_sources[lang_code])):
            source_words = self.get_frequency_list(lang_code, limit=10000, source_index=i)
            all_words.update(source_words)
        
        # Sort alphabetically for easier browsing
        sorted_words = sorted(list(all_words))
        
        # Save to file
        output_path = output_file or os.path.join(
            self.output_dir, lang_code, f"{lang_code}_combined_wordlist.txt"
        )
        
        with open(output_path, 'w', encoding='utf-8') as f:
            for word in sorted_words:
                f.write(f"{word}\n")
        
        print(f"Saved combined wordlist with {len(sorted_words)} words to {output_path}")
        return output_path


def main():
    """Main function to run the script from command line."""
    parser = argparse.ArgumentParser(description="Download and process word frequency lists")
    
    parser.add_argument("--lang", type=str, required=True, help="Language code (e.g., 'es' for Spanish)")
    parser.add_argument("--limit", type=int, default=5000, help="Maximum number of words to include")
    parser.add_argument("--source", type=int, default=0, help="Source index to use (if multiple available)")
    parser.add_argument("--word-class", type=str, help="Filter for a specific word class (e.g., 'verb')")
    parser.add_argument("--output", type=str, help="Output file path")
    parser.add_argument("--combine", action="store_true", help="Combine all sources into one wordlist")
    
    args = parser.parse_args()
    
    scraper = FrequencyListScraper()
    
    if args.combine:
        scraper.generate_complete_wordlist(args.lang, args.output)
    else:
        words = scraper.get_frequency_list(args.lang, args.limit, args.source)
        
        if args.word_class:
            words = scraper.filter_by_word_class(args.lang, words, args.word_class)
            
            # Save filtered list if requested
            if args.output:
                with open(args.output, 'w', encoding='utf-8') as f:
                    for word in words:
                        f.write(f"{word}\n")
                print(f"Saved {len(words)} {args.word_class}s to {args.output}")


if __name__ == "__main__":
    main()