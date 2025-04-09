require_relative 'form_registry'

module DictionaryScraper
  # Spanish language form definitions
  FormRegistry.register('es', 'verb', {
    mood: [:indicative, :subjunctive, :imperative],
    tense: [:present, :preterite, :imperfect, :future, :conditional, :imperfect_alternate],
    person: [1, 2, 3],
    number: [:singular, :plural],
    type: [:affirmative, :negative],
    aspect: [:simple, :perfect, :progressive, :perfect_progressive]
  })
  
  # Spanish noun forms
  FormRegistry.register('es', 'noun', {
    number: [:singular, :plural],
    gender: [:masculine, :feminine],
    type: [:diminutive, :augmentative, :regular]
  })
  
  # Spanish adjective forms
  FormRegistry.register('es', 'adjective', {
    gender: [:masculine, :feminine],
    number: [:singular, :plural],
    comparison: [:positive, :comparative, :superlative]
  })
  
  # Latin verb forms
  FormRegistry.register('la', 'verb', {
    mood: [:indicative, :subjunctive, :imperative, :infinitive],
    tense: [:present, :imperfect, :future, :perfect, :pluperfect, :future_perfect],
    voice: [:active, :passive],
    person: [1, 2, 3],
    number: [:singular, :plural]
  })
  
  # Latin noun forms
  FormRegistry.register('la', 'noun', {
    case: [:nominative, :genitive, :dative, :accusative, :ablative, :vocative, :locative],
    number: [:singular, :plural],
    gender: [:masculine, :feminine, :neuter]
  })
  
  # Latin participle forms (which act like adjectives but derive from verbs)
  FormRegistry.register('la', 'participle', {
    tense: [:present, :future, :perfect],
    case: [:nominative, :genitive, :dative, :accusative, :ablative, :vocative],
    number: [:singular, :plural],
    gender: [:masculine, :feminine, :neuter]
  })
  
  # Latin gerund forms (verbal noun)
  FormRegistry.register('la', 'gerund', {
    case: [:genitive, :dative, :accusative, :ablative]
  })
  
  # Latin supine forms
  FormRegistry.register('la', 'supine', {
    case: [:accusative, :ablative]
  })
  
  # Add more languages as needed
end