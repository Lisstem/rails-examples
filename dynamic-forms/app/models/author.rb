class Author < ApplicationRecord
  has_many :books

  default_scope { order(name: :asc) }
  scope :search, ->(term) { where('lower(name) LIKE ?', "%#{term&.downcase}%") }
end
