# Purpose

The Statute Validator has three purposes:

1. Retrieve the text of a statute.

   Example:

     Get the text of Title 21 Chapter 21.04.080:

       HTTP GET with JSON data:

         ```
         {
           statute: "T21C21.04.080"
         }
         ```

       HTTP Response:

         ```
         {
           statute: "T21C21.04.080",
           text: "The Chief Engineer is a Licensed Professional Engineer in charge of the Bureau engineering staff. The Chief Engineer, or the Chief Engineer's designee, is responsible for establishing, maintaining, and enforcing engineering and technical standards for design and construction of the water system."
         }
         ```

2. Retrieve the requirements of a statute that has corresponding quantitative requirements.

   Example:

   HTTP GET with JSON data:

   HTTP Response:


3. Determine if you are in compliance with the law by submitting relevant quantitative data 
   for a given statute.

   Example: 