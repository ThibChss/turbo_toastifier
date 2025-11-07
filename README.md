# TurboToastifier

A Rails gem for beautiful toast notifications using Turbo Streams and Stimulus controllers. Display flash messages as elegant, animated toast notifications that automatically position themselves and fade out.

## Features

- 🎨 Beautiful, animated toast notifications
- 🚀 Turbo Streams integration for seamless updates
- 📱 Responsive design with scroll-aware positioning
- ⚡ Stimulus controllers for smooth interactions
- 🎯 Simple API with helper methods
- 🔧 Easy to customize styles

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

### 1. Add the flash container to your layout

In your main layout file (usually `app/views/layouts/application.html.erb`), add the flash tag:

```erb
<%= toastified_flash_tag %>
```

### 2. Import the stylesheet

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

### 3. Import the JavaScript

The gem's JavaScript files should be automatically available through Rails' asset pipeline. Import in your main JavaScript file:

```javascript
import 'turbo_toastifier'
```

**Note for Rails 8 users:** If you encounter issues with importmap paths, the JavaScript files are still accessible through the asset pipeline. Manual importmap configuration is typically not required.

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ThibChss/turbo_toastifier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
