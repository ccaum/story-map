require 'rack'
require 'main'

use Rack::Session::Cookie,
  :key    => 'storymap.carlcaum.com',
  :secret => 'iubaOIJEWFCje834yIJf8932jcj'

run StoryMapApp
