# Notura App Documentation - 2025-04-09

## Project Setup

* **Framework**: Ruby on Rails 8.0.2
* **Language**: Ruby 3.2.2
* **Database**: PostgreSQL
* **Frontend**: Tailwind CSS, Hotwire (Turbo & Stimulus), Importmap
* **Authentication**: Devise

## Implementation Details

### Core Setup
* Created a new Rails project with PostgreSQL as the database
* Configured Importmap for JavaScript management
* Set up Tailwind CSS for styling
* Added deployment configuration with Kamal and Docker
* Configured background processing with Solid Queue, Cache and Cable

### Authentication
* Integrated Devise gem for user authentication
* Created User model with Devise modules
* Added `first_name` and `last_name` fields to User model
* Configured Devise permitted parameters in ApplicationController
* Set up email configuration in development environment

### Database Configuration
* Configured PostgreSQL connection for development and test environments
* Set database name to `notura_development` and `notura_test`
* Created separate databases for caching, queue and cable in production

### Frontend & UI
* Created Home controller with index action
* Set root path to HomeController#index
* Added login/logout links on the homepage
* Styled with Tailwind CSS
* Added conditional Flash messages for notices and alerts

### Data Models
* **User**: Authentication and user information
* **Account**: User account settings
* **Profile**: Language learning preferences and settings
* **Language**: Available languages for learning
* **ProfileLanguage**: Links profiles to languages, with proficiency levels
* **Topic**: Hierarchical organization of language content
* **LanguageGoal**: Learning goals for specific profile-language combinations

### Dictionary Scraper
* Created a custom module in `lib/dictionary_scraper/` for vocabulary collection
* **Word Model**: Comprehensive structure for storing word data including:
  * Translations across languages
  * IPA transcriptions
  * Word forms with grammatical features
  * Examples, synonyms/antonyms
  * Etymology and difficulty ratings
* **Form Registry**: Defines grammatical features by language and word class
* **Language-specific definitions**: Support for complex grammatical structures like:
  * Spanish verb conjugation patterns
  * Latin declension and conjugation forms
  * Participles, gerunds, and other derived forms
* **Word Repository**: Service for managing word collections
* **Data import/export**: JSON-based storage and retrieval

## Design Decisions

* **PostgreSQL**: Selected for its robustness and support for complex queries
* **Devise**: Chosen for comprehensive authentication functionality
* **Tailwind CSS**: Used for modern, utility-first styling approach
* **Importmap**: Selected for simple JavaScript dependency management
* **Hotwire**: Implemented for SPA-like functionality without heavy JavaScript
* **Kamal**: Added for streamlined Docker-based deployment
* **Dictionary Scraper**: Custom solution for flexibility with complex linguistic data

## Next Steps

* Add more application-specific models and controllers
* Implement personalized user information storage
* Add advanced user profile functionality
* Create public-facing web pages
* Configure hosting environment
* Implement vocabulary collection using dictionary scraper
* Build flashcards and language learning exercises