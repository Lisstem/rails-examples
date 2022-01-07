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
