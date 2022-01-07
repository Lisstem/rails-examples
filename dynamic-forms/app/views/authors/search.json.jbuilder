json.url search_authors_url(q: params[:q], format: :json)
json.results do
  json.array! @authors, partial: 'authors/author', as: :author
end
