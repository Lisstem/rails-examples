# Example for Dynamic Forms
This is an example app for dynamic forms.
Including the following features:
* Loading dropdown items
* Autocomplete for text inputs
* Adding additional fields (not finished)

This README is a guide on how i got to my solution.
The latest commit is the solution itself.

## Setup
Our setting is a simple book collection website, consisting of books, their authors and collections of those books.
To reduce the scope we will only add a controller for the collections.
The books and authors will be seeded in the library.

To start we set up a simple one to many relationship and one many to many relationship:
* One author can have multiple books and each book belongs to an author
* Each collection can have any number of books and each book can belong to any number of collections

The following commands generate the models, relationships and the controller.
```shell
bin/rails generate model author name:uniq
bin/rails generate model book name:index author:references
bin/rails generate scaffold collection name:index
bin/rails generate migration CreateJoinTableCollectionsBooks collections books
```
Afterwards update the database
```shell
bin/rails db:migrate
```

Next we add the relationships to the models:
* `has_many :books` in [app/models/author.rb](app/models/author.rb)
* `has_and_belongs_to_many :collections` in [app/models/book.rb](app/models/book.rb)
* `has_and_belongs_to_many :books` in [app/models/collection.rb](app/models/collection.rb)

To add some data for authors and their books run
```shell
bin/rails db:seed
```
The data is provided by [author_book_data.yaml](author_book_data.yaml).
You can add your favourite books if you want :)


## Loading dropdown items
In this section we make it possible to add books to our collections.
We will create a page for this purpose.
On this page we will have a dropdown for the authors and one for their books.
The goal of this section is to update the dropdown for the books whenever another author is selected.

First we add two actions to the [collections controller](app/controllers/collections_controller.rb) `add_book` and `insert_book`.
`add_book` will display the page to add the book to the collection and `insert_book` handles the post request from the former page.
To get the page to render we need to update the [routes](config/routes.rb) as well as to create the actual [view](app/views/collections/add_book.html.erb).
In the view we create a form which posts to the `insert_book_url` for our collection and which contains the dropdowns (collection_selects) for the authors and their books.
```erb
<%= form_with url: insert_book_collection_url(@collection) do |form| %>
  <% authors = Author.order(:name) %>
  # ...
    <%= form.collection_select :author_id, authors, :id, :name %>
  # ...
    <%= form.collection_select :book_id, authors.first.books, :id, :name, {} %>
  # ...
<% end %>
```
Notice that the contents of the second dropdown are set to the books of the first author. 
The first author is selected by default and this way the correct books are displayed.

To change the items in the book dropdown we can use Javascript. 
When the author dropdown is changed we will send an ajax request for the author data.
To provide this data we add a [controller for the authors](app/controllers/authors_controller.rb) which only has the show action and a [route](config/routes.rb) for this action. 
We also need a [json view](app/views/authors/show.json.jbuilder) for the show action (, I also added one for the [html view](app/views/authors/show.html.erb)).

Finally we can write our Javascript.
As this specific piece of code is only used by one page we add a [pack (app/javascript/packs/add_book.js)](app/javascript/packs/add_book.js) and include this in our [view](app/views/collections/add_book.html.erb).
```erb
<%= javascript_pack_tag 'add_book' %>
```

In [add_book.js](app/javascript/packs/add_book.js) we need to import unobtrusive javascript from rails to execute our ajax requests. 
```javascript
import Rails from "@rails/ujs"
```
Next we add an listener to the author dropdown.
```javascript
document.addEventListener("DOMContentLoaded", function() {
    document.querySelector('#author_id').addEventListener('change', function(event) {
        // ajax request goes here
    });
});
```
For the ajax request we first the url to the author after the change. 
Conveniently the id of the author is the current value of the dropdown which itself is the target of the event. 
```javascript
Rails.ajax({
    url: `/authors/${event.target.value}.json`,
    type: "get",
    success: // handle a succesful request
});
```
Now we need to add a function to handle a successful request (you can also handle an error by passing a function for `error:`).
This function will need to find our book dropdown.
Remove it's current options and add all the new options.
```javascript
function(data) {
    // get the book drop down
    let bookDropdown = document.querySelector('#book_id');
    // select all option elements in the dropdown and remove them
    bookDropdown.querySelectorAll('option').forEach( o => o.remove());
    // for each book the author has written...
    data.books.forEach(function(book) {
        // create an new option element, ...
        let option = document.createElement('option');
        // set it's value and text ...
        option.value = book.id;
        option.innerText = book.name;
        // and add it to the dropDown
        bookDropdown.appendChild(option);
    });
}
```
Putting it all together we have
```javascript
import Rails from "@rails/ujs"

document.addEventListener("DOMContentLoaded", function() {
    document.querySelector('#author_id').addEventListener('change', function(event) {
        Rails.ajax({
            url: `/authors/${event.target.value}.json`,
            type: "get",
            success: function(data) {
                // get the book drop down
                let bookDropdown = document.querySelector('#book_id');
                // select all option elements in the dropdown and remove them
                bookDropdown.querySelectorAll('option').forEach( o => o.remove());
                // for each book the author has written...
                data.books.forEach(function(book) {
                    // create an new option element, ...
                    let option = document.createElement('option');
                    // set it's value and text ...
                    option.value = book.id;
                    option.innerText = book.name;
                    // and add it to the dropDown
                    bookDropdown.appendChild(option);
                });
            }
        });
    });
});
```

## Autocomplete for text inputs
In this section we add a search function for authors with autocompletion.

First we need to add we need to add an [action](app/controllers/authors_controller.rb), views and a [route](config/routes.rb) for this.
For the search action we make use of scopes for models (see [author.rb](app/models/author.rb)) abd as a small feature we redirect directly to the author if only one matches the search term.
Both the [html view](app/views/authors/search.html.erb) and the [json view](app/views/authors/search.json.jbuilder) simply display the matching authors.

Next up we need a way to actually navigate to our search page.
For this purpose we add a small header containing a search form to our site. 
To archive this we add the code directly to the [application layout](app/views/layouts/application.html.erb).
```erb
<header>
    <nav>
      <%= link_to 'Dynamic Forms Example', root_path %>
      <%= form_with url: search_authors_url, method: :get do |f| %>
        <%= f.label :author_name, 'Search author: ' %>
        <%= search_field(:author, :name, name: :q, value: params[:q], minlength: 3, placeholder: 'author name',
                         autosave: false, autocomplete: :off, list: :search_autocomplete, 'data-search': '') %>
        <datalist id="search_autocomplete"></datalist>
        <%= f.submit 'Search' %>
      <% end %>
    </nav>
</header>
```
The most important part is the search field
```ruby
search_field(:author, :name, name: :q, value: params[:q], minlength: 3, placeholder: 'author name',
             autosave: false, autocomplete: :off, list: :search_autocomplete, 'data-search': '')
```
Let's break this down:
* The `:author` and `:name` sets the id of tag to `author_name` and the name property to `author[name]` and are required.
* As we want to use `q` as (a shorter) parameter for the search term we need to override the name attribute .
* If we already are on the search page the parameter `q` is set and we can insert it's value directly into the field for convenience.
* The `min length` is set to 3 as we want to reduce load on the the server and only search for name with more than 2 characters.
* The `placeholder` is displayed when the search field is empty.
* `autosave false` disables saving the terms in the browsers cache.
* `autocomplete off` disables the build-in autocomplete of the browser which gets in the way of our own autocomplete otherwise.
* `list` provides an id to a datalist with options for the browser to suggest.
  We will use this for our autocomplete.
  Our list is empty right know but we will fill it via javascript later.
  ```html
    <datalist id="search_autocomplete"></datalist>
  ```

Finally we get to the javascript.
We create a new [pack](app/javascript/packs/search_autocomplete.js) for this purpose.
And as search function is used on the whole site we can directly import it in the [application.js](app/javascript/packs/application.js).
As we want to send an Ajax request if the search input is changed we again need to import Rails and some event listener.
The only difference to the previous section is that the event listener on the search field listens on the input event instead of the change event.
The input event is triggered whenever the value changes but the change event only occurs when the search field looses focus.
```javascript
import Rails from "@rails/ujs"

document.addEventListener("DOMContentLoaded", function() {
    document.querySelector('#author_name').addEventListener('input', function(event) {
        // Ajax Request goes here
    });
});
```

Surprisingly (at least for me) the success function for the autocomplete and the dropdown items are mostly the same.
```javascript
let autocompleteList = document.querySelector("#search_autocomplete");
let searchTerm = event.target.value;
if (searchTerm.length >= 3) {
    Rails.ajax({
        url: `/authors/search.json?q=${searchTerm}`,
        type: "get",
        success: function (data) {
            // if the search results are already outdated when they arrive
            if (event.target.value !== searchTerm) {
                return;
            }
            // remove all current options
            autocompleteList.querySelectorAll('option').forEach(o => o.remove());
            // add new options
            data.results.forEach(function (author) {
                let option = document.createElement('option');
                option.value = author.name;
                autocompleteList.appendChild(option);
            });
        }
    });
}
```
We request the data, remove all the current options and then add the new options.
The only differences are that we only send a request if the search term is at least 3 characters and after receiving the data we check whether it's already outdated (due to the delay).
(There still is the concurrency problem of potentially modifying the options through 2 requests, but i hope it will be fine)

Hurray, autocomplete is working now \o/
... but it generates lots of request as every character change issues a new on. 
Luckily there are a few ways to improve performance.

First of we do not need to issue a new request if all the current options still match the new search term.  
Also if we add another character to our search term all of the hits still match the old search term and should be part of the current options.
The only problem here is that the options are limited to 100.
So if we already have 100 options might miss some options and we need to query them again.

As a last improvement we can insert a small delay between the start of the event and executing the Ajax request.
If the search term has changed during the delay we do not need to send the request.
I personally feel that even a delay of half a second still feels fine and it really cuts down on the requests.
Especially when the user is using backspace.

Putting all together yield
```javascript
import Rails from "@rails/ujs"

function updateRequired(newTerm, oldTerm, oldOptions) {
    if (newTerm.length < 3) {
        return false;
    }
    if (oldTerm === '' || !newTerm.match(oldTerm)) {
        return true;
    }
    let entries = oldOptions.length;
    let rehit = 0; oldOptions.forEach(o => o.value.match(newTerm) ? rehit++: 0);
    return entries === 100 && rehit < entries;
}

document.addEventListener("DOMContentLoaded", function() {
    let autocompleteList = document.querySelector("#search_autocomplete");
    let oldTerm = ""
    document.querySelector('#author_name').addEventListener('input', function(event) {
        let searchTerm = event.target.value;
        // add small delay
        setTimeout(() => {
            // check if term is still update to date and if an update is required
            if (event.target.value === searchTerm && updateRequired(searchTerm, oldTerm, autocompleteList.querySelectorAll('option'))) {
                Rails.ajax({
                    url: `/authors/search.json?q=${searchTerm}`,
                    type: "get",
                    success: function (data) {
                        // if the search results are already outdated when they arrive
                        if (event.target.value !== searchTerm) {
                            return;
                        }
                        // set search term als old term
                        oldTerm = searchTerm;
                        // remove all current options
                        autocompleteList.querySelectorAll('option').forEach(o => o.remove());
                        // add new options
                        data.results.forEach(function (author) {
                            let option = document.createElement('option');
                            option.value = author.name;
                            autocompleteList.appendChild(option);
                        });
                    }
                });
            }}, 500);
    });
});
```
