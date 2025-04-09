module DictionaryScraper
  class LanguageForms
    # Registry of language-specific form definitions
    @form_definitions = {}
    
    class << self
      attr_reader :form_definitions
      
      def register(language_code, word_classes)
        @form_definitions[language_code] = word_classes
      end
      
      def forms_for(language_code, word_class)
        return {} unless @form_definitions[language_code]
        @form_definitions[language_code][word_class.to_sym] || {}
      end
      
      def word_classes_for(language_code)
        return [] unless @form_definitions[language_code]
        @form_definitions[language_code].keys
      end
    end
  end
end