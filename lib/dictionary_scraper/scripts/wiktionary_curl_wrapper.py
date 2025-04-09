#!/usr/bin/env python3
"""
Wiktionary Curl Wrapper - Uses subprocess to run curl for fetching Wiktionary pages

This script provides a wrapper around curl for fetching Wiktionary pages, which
may be necessary in environments where Python's requests library is restricted.
"""

import os
import subprocess
import tempfile
import time
from typing import Optional
from urllib.parse import quote


class WiktionaryCurlWrapper:
    """Wrapper around curl for fetching Wiktionary pages."""
    
    def __init__(self, rate_limit: float = 1.0, user_agent: Optional[str] = None):
        """Initialize the wrapper.
        
        Args:
            rate_limit: Time in seconds to wait between requests
            user_agent: Custom user agent string (optional)
        """
        self.rate_limit = rate_limit
        self.user_agent = user_agent or "Notura Language Learning App/1.0 (Dictionary Data Collection)"
        self.last_request_time = 0
    
    def fetch_page(self, word: str) -> Optional[str]:
        """Fetch a Wiktionary page for a word using curl.
        
        Args:
            word: The word to fetch from Wiktionary
            
        Returns:
            HTML content of the page or None if the request failed
        """
        # Rate limiting
        current_time = time.time()
        elapsed = current_time - self.last_request_time
        if elapsed < self.rate_limit:
            time.sleep(self.rate_limit - elapsed)
        
        # URL encode the word
        encoded_word = quote(word)
        url = f"https://en.wiktionary.org/wiki/{encoded_word}"
        
        # Create a temporary file to store the response
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_path = temp_file.name
        
        try:
            # Build the curl command
            curl_cmd = [
                "curl",
                "-s",  # Silent mode
                "-o", temp_path,  # Output to file
                "-A", self.user_agent,  # User agent
                "-L",  # Follow redirects
                "--max-time", "30",  # Timeout
                url
            ]
            
            # Execute curl command
            process = subprocess.run(
                curl_cmd,
                check=False,  # Don't raise exception on non-zero exit
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # Check if curl succeeded
            if process.returncode != 0:
                error = process.stderr.decode('utf-8', errors='replace')
                print(f"Curl error for {word}: {error}")
                return None
            
            # Read the response from the temporary file
            with open(temp_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            # Update the last request time
            self.last_request_time = time.time()
            
            # Check if the page exists (Wiktionary returns 200 even for missing pages)
            if "Wiktionary does not have an entry for this term" in content:
                print(f"No entry found for {word}")
                return None
            
            return content
        
        except Exception as e:
            print(f"Error fetching {word}: {str(e)}")
            return None
        
        finally:
            # Clean up the temporary file
            if os.path.exists(temp_path):
                os.unlink(temp_path)


# Example usage
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <word>")
        sys.exit(1)
    
    word = sys.argv[1]
    wrapper = WiktionaryCurlWrapper()
    content = wrapper.fetch_page(word)
    
    if content:
        output_file = f"{word}_wiktionary.html"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Saved content to {output_file}")
    else:
        print(f"Failed to fetch content for {word}")