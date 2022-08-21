class Comment < ActiveRecord::Base
  belongs_to :article, counter_cache: true
end
