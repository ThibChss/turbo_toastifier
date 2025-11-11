# TurboToastifier

A Rails gem for beautiful toast notifications using Turbo Streams and Stimulus controllers. Display flash messages as elegant, animated toast notifications that automatically position themselves and fade out.

## Features

- 🎨 Beautiful, animated toast notifications
- 🚀 Turbo Streams integration for seamless updates
- 📱 Responsive design with scroll-aware positioning
- ⚡ Stimulus controllers for smooth interactions
- 🎯 Simple API with helper methods
- 🔧 Easy to customize styles
- ⏸️ Pause on hover - messages pause their animation when hovered
- 📋 Queue system - messages only start disappearing after the first one is removed
- 🔢 Configurable message limit - limit how many messages are visible at once
- ✕ Manual dismiss button - close button appears when auto-removal is disabled
- 🎛️ Per-flash-type configuration - different durations for different flash types

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'turbo_toastifier'
```

And then execute:

```bash
bundle install
```

## Setup

### 1. Generate the initializer

Run the generator to create the configuration file:

```bash
rails generate turbo_toastifier:install
```

This will create `config/initializers/turbo_toastifier.rb` with detailed comments explaining all configuration options.

### 2. Configure defaults (optional)

Edit `config/initializers/turbo_toastifier.rb` to customize the behavior:

```ruby
TurboToastifier.configure do |config|
  # Maximum number of messages to display at once (0 = unlimited)
  config.limit = 5

  # Display duration in seconds, or a hash of flash_type => duration
  # Examples:
  #   config.duration = 4  # All messages disappear after 4 seconds
  #   config.duration = { notice: 4, alert: 0 }  # Notice disappears after 4s, alert never disappears
  #   config.duration = 0  # All messages never disappear (shows close button for all)
  config.duration = 4
end
```

**Configuration Options:**

#### `limit` (Integer)
- Maximum number of messages to display at once
- Set to `0` for unlimited messages (default)
- When set to a positive integer, only that many messages will be visible at once
- Additional messages will be queued and automatically appear when visible messages are removed
- Useful for preventing screen clutter when many notifications are triggered

#### `duration` (Integer or Hash)
- Display duration in seconds, or a hash of flash_type => duration
- **Integer**: All messages will use the same duration
  - Positive integer: Message will auto-remove after that many seconds
  - `0`: Message will never auto-remove (shows close button for manual dismissal)
- **Hash**: Each flash type can have its own duration
  ```ruby
  config.duration = {
    notice: 4,   # Auto-remove after 4 seconds
    alert: 0,    # Manual dismissal required
    success: 5,  # Auto-remove after 5 seconds
    error: 0     # Manual dismissal required
  }
  ```

**Close Button:**
- When `duration` is set to `0` for a message (either globally or per flash type), a close button (✕) appears in the top-right corner
- Clicking the close button triggers an animated dismiss
- Once manually dismissed, hover will not restart the animation
- This is useful for important messages that users should explicitly acknowledge

#### `dismiss` (Symbol)
- Controls how users can dismiss flash messages
- **`:button`** (default): Only the close button (✕) can dismiss messages
- **`:click`**: Click anywhere on the message to dismiss
  - Clicking on links or buttons inside the message will NOT dismiss it
  - The close button is hidden when using `:click` mode (unless `duration` is 0)
- Examples:
  ```ruby
  config.dismiss = :button  # Only close button (default)
  config.dismiss = :click   # Click anywhere to dismiss
  ```

### 3. Add the flash container to your layout

In your main layout file (usually `app/views/layouts/application.html.erb`), add the flash tag:

```erb
<%= toastified_flash_tag %>
```

This will use the defaults configured in your initializer.

### 4. Import the stylesheet

Add to your main stylesheet (e.g., `app/assets/stylesheets/application.scss`):

```scss
@import 'turbo_toastifier';
```

Or if using a CSS manifest:

```css
/*
 *= require turbo_toastifier
 */
```

### 5. Import the JavaScript

#### If using importmap

**Option 1: Single bundled file (recommended)**

The gem provides a bundled version that works out of the box. Simply add to your `config/importmap.rb`:

```ruby
pin 'turbo_toastifier', to: 'turbo_toastifier.js'
```

Then in your main JavaScript file (e.g., `app/javascript/application.js`):

```javascript
import 'turbo_toastifier'
```

**Option 2: Separate controller files**

If you prefer to use the separate controller files, you'll need to pin each file in your `config/importmap.rb`:

```ruby
pin 'turbo_toastifier', to: 'turbo_toastifier.js'
pin 'turbo_toastifier/controllers/flash_removal_controller', to: 'turbo_toastifier/controllers/flash_removal_controller.js'
pin 'turbo_toastifier/controllers/flash_scroll_controller', to: 'turbo_toastifier/controllers/flash_scroll_controller.js'
```

The controllers will be automatically registered with Stimulus. The gem will try to find the Stimulus application via `window.application` or `window.Stimulus`.

**Note:** Make sure `@hotwired/stimulus` is already pinned in your importmap (it should be by default in Rails 7+).

#### If using a bundler (esbuild, webpack, etc.)

Import the JavaScript file directly. The bundler will automatically resolve the relative imports:

```javascript
import 'turbo_toastifier'
```

Or import the controllers directly if needed:

```javascript
import FlashRemovalController from 'turbo_toastifier/controllers/flash_removal_controller.js'
import FlashScrollController from 'turbo_toastifier/controllers/flash_scroll_controller.js'
```

## Usage

### In Controllers

The gem automatically includes the `TurboToastifier::Controller` concern in all controllers, so you can use the following methods:

#### Basic toast notifications

```ruby
class PostsController < ApplicationController
  def create
    @post = Post.new(post_params)

    if @post.save
      toast(:notice, 'Post created successfully!')
      redirect_to @post
    else
      toast(:alert, 'Failed to create post')
      render :new
    end
  end
end
```

#### HTML content in toasts

By default, all messages are HTML-escaped for security. To include HTML content (like links), mark the message as safe:

```ruby
def show
  post_link = helpers.link_to('View post', @post)
  toast(:notice, "Post updated! #{post_link}".html_safe)
end

# Or using content_tag
def create
  message = content_tag(:strong, 'Success!') + ' Post created.'
  toast(:notice, message.html_safe)
end

# Or with toastified_render/redirect
def update
  link = helpers.link_to('View', post_path(@post))
  toastified_redirect(posts_path, notice: "Updated! #{link}".html_safe)
end
```

**Security Note:** Only use `.html_safe` with content you trust. Never use it with user-generated content without proper sanitization.

#### Using toastified_render

```ruby
def create
  @post = Post.new(post_params)

  if @post.save
    toastified_render(:show, notice: 'Post created successfully!')
  else
    toastified_render(:new, alert: 'Failed to create post', status: :unprocessable_entity)
  end
end
```

**Note:** `toastified_render` is compatible with Phlex components. You can pass Phlex components directly:

```ruby
def show
  toastified_render(Posts::ShowComponent.new(@post), notice: 'Post loaded!')
end
```

When `component` is `nil`, only the Turbo Stream format is rendered (useful for Turbo-only responses).

#### Using toastified_redirect

```ruby
def update
  @post = Post.find(params[:id])

  if @post.update(post_params)
    toastified_redirect(posts_path, notice: 'Post updated successfully!')
  else
    render :edit, alert: 'Failed to update post'
  end
end
```

#### Using toastified_turbo_frame

Handle both Turbo Frame requests and regular requests:

```ruby
def create
  @post = Post.new(post_params)

  if @post.save
    toastified_turbo_frame(
      component: :show,
      notice: 'Post created successfully!',
      fallback: {
        action: :redirect,
        path: posts_path
      }
    )
  else
    toastified_turbo_frame(
      component: :new,
      alert: 'Failed to create post',
      fallback: {
        action: :render,
        component: :new
      }
    )
  end
end
```

### Toast Types

The gem automatically supports all flash types defined in your Rails application. By default, Rails provides `:notice` and `:alert` flash types, and the gem will automatically detect and support any additional custom types you add via `add_flash_types`.

#### Custom Flash Types

You can add custom flash types using Rails' native `add_flash_types` method in your `ApplicationController`. The gem will automatically detect and support all flash types, including your custom ones.

```ruby
# In your ApplicationController
class ApplicationController < ActionController::Base
  add_flash_types :success, :error, :warning, :info
end
```

Now you can use any of these types in your controllers:

```ruby
toastified_redirect(posts_path, success: 'Post created!', error: 'Something went wrong')
toast(:info, 'Just so you know...')
```

The gem will automatically pick up all flash types from `ApplicationController._flash_types` (which includes both default and custom types added via `add_flash_types`).

### Schedule Options

You can control when toasts appear using the `schedule` parameter:

- `:now` - Display immediately (uses `flash.now`)
- `:later` - Display on next request (uses `flash`)

```ruby
# Display immediately
toast(:notice, 'This appears now', schedule: :now)

# Display on next request
toast(:notice, 'This appears later', schedule: :later)
```

## Customization

### Styling

#### Option 1: Generate Custom Stylesheet (Recommended for Complete Overrides)

If you want to completely customize the styles, generate a custom stylesheet:

```bash
rails generate turbo_toastifier:style
```

This creates `app/assets/stylesheets/turbo_toastifier.scss` with all the default styles that you can customize. After generating, make sure your main stylesheet imports this file instead of the gem's default styles:

```scss
// In app/assets/stylesheets/application.scss
@import 'turbo_toastifier';  // This will use your custom styles
```

**Note:** The generated file includes all default styles, so you can modify them as needed. The file includes helpful comments and examples for common customizations.

#### Option 2: Override Default Styles

You can override the default styles by importing the gem's styles first, then adding your customizations:

```scss
// Import the gem's styles first
@import 'turbo_toastifier';

// Then override with your custom styles (these will take precedence)
.flash {
  &__message {
    // Override any default message styles
    background: #your-color;
    color: #your-text-color;
  }

  &__message.--notice {
    border-left-color: #your-notice-color;
  }

  &__message.--alert {
    border-left-color: #your-alert-color;
  }

  &__message.--warning {
    border-left-color: #your-warning-color;
  }
}

// Add styles for custom flash types
.flash__message.--success {
  border-left: 4px solid #your-success-color;
}

.flash__message.--error {
  border-left: 4px solid #your-error-color;
}

.flash__message.--info {
  border-left: 4px solid #your-info-color;
}
```

**Important:** Make sure your custom styles are imported **after** `@import 'turbo_toastifier';` so they can override the default styles. If your styles still don't apply, you may need to increase specificity or use `!important` for specific properties.

### Behavior

The gem includes smart queue management and hover behavior:

- **Queue System**: Messages only start their auto-removal animation after the first message in the list has been removed. This prevents multiple messages from disappearing simultaneously.
- **Hover to Pause**: When you hover over a message, its animation pauses, allowing you to read it without it disappearing. The animation resumes when you move your mouse away.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the Ruby tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

#### Ruby Tests (RSpec)

Run the Ruby tests with:

```bash
bundle exec rspec
```

#### JavaScript Tests (Jest)

The gem includes JavaScript tests using Jest (similar to RSpec for JavaScript). To run them:

1. Install Node.js dependencies:
```bash
npm install
```

2. Run the JavaScript tests:
```bash
npm test
```

3. Run tests in watch mode:
```bash
npm run test:watch
```

4. Run tests with coverage:
```bash
npm run test:coverage
```

The JavaScript tests are located in `spec/javascript/` and test the Stimulus controllers:
- `spec/javascript/turbo_toastifier/flash_removal_controller_spec.js` - Tests for pause, resume, and removal logic
- `spec/javascript/turbo_toastifier/flash_scroll_controller_spec.js` - Tests for max messages enforcement and scroll handling

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ThibChss/turbo_toastifier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
