class Author < ApplicationRecord
  has_many :books

  scope :search, ->(term) { where('lower(name) LIKE ?', "%#{term&.downcase}%") }
end
