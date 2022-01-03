# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
data = YAML.load_file('author_book_data.yaml')
data.each do |author_data|
  author = Author.find_by_name(author_data['name']) || Author.new(name: author_data['name'])
  author.save
  author.books = author_data['books'].map { |name| author.books.find_by_name(name) || Book.new(name: name) }
end
