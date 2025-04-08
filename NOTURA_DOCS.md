# Notura App Documentation - 2025-04-08

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

### Routing
* Configured root route to home#index
* Set up Devise routes

## Design Decisions

* **PostgreSQL**: Selected for its robustness and support for complex queries
* **Devise**: Chosen for comprehensive authentication functionality
* **Tailwind CSS**: Used for modern, utility-first styling approach
* **Importmap**: Selected for simple JavaScript dependency management
* **Hotwire**: Implemented for SPA-like functionality without heavy JavaScript
* **Kamal**: Added for streamlined Docker-based deployment

## Next Steps

* Add more application-specific models and controllers
* Implement personalized user information storage
* Add advanced user profile functionality
* Create public-facing web pages
* Configure hosting environment
* Implement business logic specific to the app