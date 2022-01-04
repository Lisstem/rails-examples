json.extract! author, :id, :name, :created_at, :updated_at
json.books do
  json.array! author.books, :id, :name, :created_at, :updated_at
end
json.url author_url(author, format: :json)
