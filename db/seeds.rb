# This file populates the database with initial data for Notura.

# Clear existing data - only for development environment
if Rails.env.development?
  puts "Clearing existing data..."
  LanguageGoal.destroy_all
  ProfileLanguage.destroy_all
  Topic.destroy_all
  Profile.destroy_all
  Account.destroy_all
  Language.destroy_all
end

# Create languages
puts "Creating languages..."
languages = [
  { code: "en", name: "English", display_name: "English" },
  { code: "es", name: "Spanish", display_name: "Español" },
  { code: "fr", name: "French", display_name: "Français" },
  { code: "de", name: "German", display_name: "Deutsch" },
  { code: "it", name: "Italian", display_name: "Italiano" },
  { code: "pt", name: "Portuguese", display_name: "Português" },
  { code: "ru", name: "Russian", display_name: "Русский" },
  { code: "ja", name: "Japanese", display_name: "日本語" },
  { code: "zh", name: "Chinese", display_name: "中文" },
  { code: "ko", name: "Korean", display_name: "한국어" }
]

created_languages = languages.map do |lang_data|
  Language.find_or_create_by!(code: lang_data[:code]) do |lang|
    lang.name = lang_data[:name]
    lang.display_name = lang_data[:display_name]
    lang.is_available = true
  end
end

# Create topics hierarchy
puts "Creating topics..."
# Root topics
grammar = Topic.find_or_create_by!(name: "Grammar", parent: nil, difficulty_level: 1)
vocabulary = Topic.find_or_create_by!(name: "Vocabulary", parent: nil, difficulty_level: 1)
conversation = Topic.find_or_create_by!(name: "Conversation", parent: nil, difficulty_level: 2)
literature = Topic.find_or_create_by!(name: "Literature", parent: nil, difficulty_level: 3)
culture = Topic.find_or_create_by!(name: "Culture", parent: nil, difficulty_level: 2)

# Grammar subtopics
Topic.find_or_create_by!(name: "Verbs", parent: grammar, difficulty_level: 1)
Topic.find_or_create_by!(name: "Nouns", parent: grammar, difficulty_level: 1)
Topic.find_or_create_by!(name: "Adjectives", parent: grammar, difficulty_level: 2)
Topic.find_or_create_by!(name: "Syntax", parent: grammar, difficulty_level: 3)

# Vocabulary subtopics
Topic.find_or_create_by!(name: "Common Words", parent: vocabulary, difficulty_level: 1)
Topic.find_or_create_by!(name: "Food", parent: vocabulary, difficulty_level: 1)
Topic.find_or_create_by!(name: "Travel", parent: vocabulary, difficulty_level: 2)
Topic.find_or_create_by!(name: "Business", parent: vocabulary, difficulty_level: 3)
Topic.find_or_create_by!(name: "Technology", parent: vocabulary, difficulty_level: 2)

# Conversation subtopics
Topic.find_or_create_by!(name: "Greetings", parent: conversation, difficulty_level: 1)
Topic.find_or_create_by!(name: "Small Talk", parent: conversation, difficulty_level: 2)
Topic.find_or_create_by!(name: "Debate", parent: conversation, difficulty_level: 4)

# Create a demo account if in development
if Rails.env.development?
  puts "Creating demo account..."
  demo_account = Account.find_or_create_by!(email: "demo@example.com") do |account|
    account.password_hash = "demo_hash_not_for_production"
    account.salt = "demo_salt_not_for_production"
  end
  
  demo_profile = demo_account.profile
  demo_profile.update(
    username: "language_learner",
    preferences: {
      ui_theme: "dark",
      notifications_enabled: true,
      daily_goal_reminder: true,
      study_reminder_time: "18:00"
    }
  )
  
  # Add languages to demo profile
  english = Language.find_by(code: "en")
  spanish = Language.find_by(code: "es")
  french = Language.find_by(code: "fr")
  
  # Native language
  english_profile = ProfileLanguage.find_or_create_by!(profile: demo_profile, language: english) do |pl|
    pl.is_native = true
    pl.learning_active = false
    pl.proficiency_level = {
      reading: 5,
      writing: 5,
      listening: 5,
      speaking: 5
    }
  end
  
  # Learning languages
  spanish_profile = ProfileLanguage.find_or_create_by!(profile: demo_profile, language: spanish) do |pl|
    pl.is_native = false
    pl.learning_active = true
    pl.proficiency_level = {
      reading: 3,
      writing: 2,
      listening: 2,
      speaking: 2
    }
  end
  
  french_profile = ProfileLanguage.find_or_create_by!(profile: demo_profile, language: french) do |pl|
    pl.is_native = false
    pl.learning_active = true
    pl.proficiency_level = {
      reading: 1,
      writing: 1,
      listening: 1,
      speaking: 1
    }
  end
  
  # Add some goals
  grammar_topic = Topic.find_by(name: "Grammar")
  vocab_topic = Topic.find_by(name: "Vocabulary")
  conv_topic = Topic.find_by(name: "Conversation")
  
  LanguageGoal.find_or_create_by!(profile_language: spanish_profile, topic: grammar_topic) do |goal|
    goal.target_level = 4
    goal.target_date = 3.months.from_now
  end
  
  LanguageGoal.find_or_create_by!(profile_language: spanish_profile, topic: vocab_topic) do |goal|
    goal.target_level = 3
    goal.target_date = 2.months.from_now
  end
  
  LanguageGoal.find_or_create_by!(profile_language: french_profile, topic: grammar_topic) do |goal|
    goal.target_level = 2
    goal.target_date = 6.months.from_now
  end
end

puts "Seeding completed!"
