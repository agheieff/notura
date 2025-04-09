# Notura

Notura is a language learning application built with Ruby on Rails that helps users learn and practice multiple languages.

## Setup Instructions

### Requirements
* Ruby 3.2.2
* Rails 8.0.2
* PostgreSQL
* Node.js and Yarn

### Installation
1. Clone the repository
2. Install dependencies: `bundle install`
3. Install JavaScript dependencies: `yarn install`
4. Create database: `bin/rails db:create`
5. Run migrations: `bin/rails db:migrate`
6. Seed initial data: `bin/rails db:seed`
7. Start the server: `bin/dev`

## Key Features

* User authentication with Devise
* Profile management for language learning preferences
* Language and topic selection
* Progress tracking for different language skills (reading, writing, listening, speaking)
* Dictionary scraper for vocabulary data collection

## Project Structure

### MVC Components
* **Models**: User, Profile, Language, ProfileLanguage, Topic, etc.
* **Views**: Structured with Tailwind CSS components
* **Controllers**: Organized by feature

### Dictionary Scraper
Located in the `lib/dictionary_scraper` directory:
* `models/` - Data structures for words and language features
* `services/` - API clients and word repositories
* `parsers/` - Parse responses from dictionary sources
* `exporters/` - Export to various formats
* `data/` - Store word lists and outputs
* `tasks/` - Rake tasks for import/export

## Development Commands
* **Server**: `bin/dev` (runs Rails server with Tailwind)
* **Tests**: `bin/rails test`
* **Linting**: `bin/rubocop` (check), `bin/rubocop -a` (auto-fix)
* **Console**: `bin/rails console`
* **Database**: `bin/rails db:migrate`, `bin/rails db:seed`

## Contributing
1. Follow the style guidelines in CLAUDE.md
2. Write tests for new features
3. Keep controllers thin, moving business logic to models or services
4. Document new features in the appropriate files