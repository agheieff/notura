#!/bin/bash

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR/../data"
RESULTS_DIR="$DATA_DIR/results"

# Create directories if they don't exist
mkdir -p "$DATA_DIR"
mkdir -p "$RESULTS_DIR"

# Set Python virtual environment if available
if [ -d "$SCRIPT_DIR/../venv" ]; then
  source "$SCRIPT_DIR/../venv/bin/activate"
fi

function show_usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --language LANG    Language code to scrape (default: es)"
  echo "  --word WORD        Scrape a single word"
  echo "  --frequency N      Scrape top N frequent words"
  echo "  --wordclass CLASS  Filter by word class (e.g. verb, noun)"
  echo "  --combine          Combine all frequency sources"
  echo "  --help             Show this help message"
}

# Default values
LANGUAGE="es"
FREQUENCY=100
WORDCLASS=""
ACTION=""
WORD=""
COMBINE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --language)
      LANGUAGE="$2"
      shift 2
      ;;
    --word)
      WORD="$2"
      ACTION="word"
      shift 2
      ;;
    --frequency)
      FREQUENCY="$2"
      ACTION="frequency"
      shift 2
      ;;
    --wordclass)
      WORDCLASS="$2"
      shift 2
      ;;
    --combine)
      COMBINE=true
      ACTION="combine"
      shift
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Set output paths
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FREQUENCY_OUTPUT="$DATA_DIR/${LANGUAGE}_top_${FREQUENCY}_words.txt"
WIKTIONARY_OUTPUT="$RESULTS_DIR/${LANGUAGE}_wiktionary_${TIMESTAMP}.json"

# Show configuration
echo "=============================================="
echo "Notura Dictionary Scraper"
echo "=============================================="
echo "Language: $LANGUAGE"
if [ "$ACTION" == "word" ]; then
  echo "Mode: Scraping single word: '$WORD'"
elif [ "$ACTION" == "frequency" ]; then
  echo "Mode: Scraping top $FREQUENCY words"
  if [ -n "$WORDCLASS" ]; then
    echo "Word class filter: $WORDCLASS"
  fi
elif [ "$ACTION" == "combine" ]; then
  echo "Mode: Combining all frequency sources"
else
  echo "No action specified. Use --word, --frequency, or --combine"
  exit 1
fi
echo "=============================================="

# Step 1: Get word list (if not scraping a single word)
if [ "$ACTION" == "frequency" ]; then
  echo "Step 1: Getting frequency list for $LANGUAGE..."
  
  if [ -n "$WORDCLASS" ]; then
    python "$SCRIPT_DIR/frequency_list_scraper.py" --lang "$LANGUAGE" --limit "$FREQUENCY" --word-class "$WORDCLASS" --output "$FREQUENCY_OUTPUT"
  else
    python "$SCRIPT_DIR/frequency_list_scraper.py" --lang "$LANGUAGE" --limit "$FREQUENCY" --output "$FREQUENCY_OUTPUT"
  fi
  
  if [ ! -f "$FREQUENCY_OUTPUT" ]; then
    echo "Error: Failed to generate frequency list"
    exit 1
  fi
  
  WORD_COUNT=$(wc -l < "$FREQUENCY_OUTPUT")
  echo "Generated list with $WORD_COUNT words"

elif [ "$ACTION" == "combine" ]; then
  echo "Step 1: Combining all frequency sources for $LANGUAGE..."
  
  python "$SCRIPT_DIR/frequency_list_scraper.py" --lang "$LANGUAGE" --combine --output "$FREQUENCY_OUTPUT"
  
  if [ ! -f "$FREQUENCY_OUTPUT" ]; then
    echo "Error: Failed to generate combined wordlist"
    exit 1
  fi
  
  WORD_COUNT=$(wc -l < "$FREQUENCY_OUTPUT")
  echo "Generated combined list with $WORD_COUNT words"
  
  # Set action to frequency for the next step
  ACTION="frequency"
fi

# Step 2: Scrape from Wiktionary
echo "Step 2: Scraping Wiktionary data..."

if [ "$ACTION" == "word" ]; then
  python "$SCRIPT_DIR/wiktionary_scraper.py" --lang "$LANGUAGE" --word "$WORD" --output "$WIKTIONARY_OUTPUT"
  
  echo "Results saved to: $WIKTIONARY_OUTPUT"

elif [ "$ACTION" == "frequency" ]; then
  python "$SCRIPT_DIR/wiktionary_scraper.py" --lang "$LANGUAGE" --word-list "$FREQUENCY_OUTPUT" --output "$WIKTIONARY_OUTPUT" --rate-limit 1.5
  
  # Count results
  RESULT_COUNT=$(grep -o '"text":' "$WIKTIONARY_OUTPUT" | wc -l)
  echo "Successfully scraped $RESULT_COUNT words out of $WORD_COUNT"
  echo "Results saved to: $WIKTIONARY_OUTPUT"
fi

# Step 3: Import into application (if needed)
echo "Step 3: To import into the Rails application, run:"
echo "cd $(realpath "$SCRIPT_DIR/../../..")"
echo "bin/rails dictionary:import[$WIKTIONARY_OUTPUT]"

echo "Done!"