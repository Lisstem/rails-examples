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
