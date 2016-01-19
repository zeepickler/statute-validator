### Purpose
#### The Statute Validator has three purposes:
##### Retrieve the text of a statute.

Example: Get the text of Title 21 Chapter 21.04.080.

HTTP GET with JSON data:

``` javascript
{statutes: [{statute: "21.04.080",
            retrieve: ["text"]}]}
```

HTTP Response:

``` javascript
{statutes: [{statute: "21.04.080",
                text: `The Chief Engineer is a Licensed Professional Engineer in charge of the Bureau
                       engineering staff. The Chief Engineer, or the Chief Engineer's designee, is 
                       responsible for establishing, maintaining, and enforcing engineering and 
                       technical standards for design and construction of the water system.`}]}
```

##### Retrieve the requirements of a statute (only for statutes with quantitative requirements).

Example: Get the requirements of Title 21 Chapter 21.12.140.

HTTP GET with JSON data:

``` javascript
{statutes: [{statute: "21.12.140",
            retrieve: ["requirements"]}]}
```

HTTP Response:

``` javascript
{statutes: [{statute: "21.12.140",
             requirements: [{conditional: "include",
                             sources: {include: ["water pressure"]},
                             location: {include: ["at the meter"]},
                             value: [{minimum: 20}],
                             units: "psi"},
                            {conditional: "include",
                             sources: {include: ["water pressure"]},
                             location: {include: ["pumps","elevated reservoirs","tanks"]},
                             value: [{minimum: 40},
                                     {maximum: 110}],
                             units: "psi"},
                            {conditional: "include",
                             sources: {include: ["water pressure"]},
                             location: {include: ["private property"]},
                             value: [{minimum: 80}],
                             units: "psi",
                             requires: "Requires a pressure reducing device for on-site domestic water systems."}]}]},
                            {conditional: "include",
                             sources: ["water pressure"],
                             location: {include: ["to the service"]},
                             value: [{minimum: 20},
                                     {maximum: 40}],
                             units: "psi",
                             optional: `The water user may choose to install a booster pump system on the 
                                        premises to improve the working of the private plumbing system. 
                                        The property owner or ratepayer is responsible for the installation, 
                                        operation and maintenance of any pressure boosting system. The 
                                        addition of a booster pump will require an appropriate backflow 
                                        prevention assembly be installed on the water service, on private 
                                        property, and directly adjacent to the property line, as required by
                                        City Code Section 21.12.320.`}]}
```

##### Determine statute compliance by providing the observed quantitative data.

Example: Provide observed data for Title 21 Chapter 21.12.140 and determine compliance.

HTTP GET with JSON data:

``` javascript
{statutes: [{statute: "21.12.140",
             retrieve: ["compliance"],
             observed_data: {sources: ["water pressure"],
                             location: ["to property line"],
                             value: 30,
                             units: "psi"}}]}
```

HTTP Response (with the result being that the data parameters are in compliance):

``` javascript
{statutes: [{statute: "21.12.140",
             compliance: true}]}
```