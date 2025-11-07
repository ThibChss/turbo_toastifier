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

### 3. Import the JavaScript (if using importmap)

If you're using importmap, add to your `config/importmap.rb`:

```ruby
pin 'turbo_toastifier', to: 'turbo_toastifier.js'
```

Then import in your main JavaScript file:

```javascript
import 'turbo_toastifier'
```

If you're using a bundler (esbuild, webpack, etc.), import the JavaScript file directly:

```javascript
import 'turbo_toastifier'
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

You can override the default styles by importing the SCSS file and customizing variables:

```scss
@import 'turbo_toastifier/flash';

// Override default colors
.flash {
  &__message.--notice {
    border-left-color: #your-color;
  }

  &__message.--alert {
    border-left-color: #your-color;
  }

  &__message.--warning {
    border-left-color: #your-color;
  }
}
```

Then add corresponding styles for your custom types:

```scss
.flash__message.--success {
  border-left: 4px solid #your-color;
}

.flash__message.--error {
  border-left: 4px solid #your-color;
}

.flash__message.--info {
  border-left: 4px solid #your-color;
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ThibChss/turbo_toastifier.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
