# Example for Dynamic Forms
This is an example app for dynamic forms.
Including the following features:
* Loading dropdown items
* Search completion for text inputs (not finished)
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

And everything works now, but we should add some security to our url regeneration.
We probably should check if the current value of the author dropdown actually is an id as some might tinker with it.
To do this we only send a request if the value only consists of digits and otherwise display an error prompt.
See [add_book.js](app/javascript/packs/add_book.js) for this addition.
