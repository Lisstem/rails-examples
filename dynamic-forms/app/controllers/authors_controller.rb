class AuthorsController < ApplicationController
  def show
    @author = Author.find(params[:id])
  end
  
  def search
    params.require(:q)

    @authors = Author.search(params[:q]).limit(params[:limit] || 100)
    redirect_to author_url(@authors.first) if @authors.count == 1 && params[:format] == :html
  end
end
