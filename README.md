# Purpose

The Statute Validator has three purposes:

1. Retrieve the text of a statute.

Example: Get the text of Title 21 Chapter 21.04.080.

HTTP GET with JSON data:

``` javascript
{
 statute: "21.04.080"
 retrieve: ["text"]
}
```

HTTP Response:

``` javascript
{
 statute: "21.04.080",
 text: "The Chief Engineer is a Licensed Professional Engineer in charge of the Bureau engineering staff. The Chief Engineer, or the Chief Engineer's designee, is responsible for establishing, maintaining, and enforcing engineering and technical standards for design and construction of the water system."
}
```

2. Retrieve the requirements of a statute that has corresponding quantitative requirements.

Example: Get the requirements of Title 21 Chapter 21.12.140.

HTTP GET with JSON data:

``` javascript
{
 "statute": "21.12.140",
 "retrieve": ["requirements"]
}
```

HTTP Response:

#######
http://www.portlandonline.com/auditor/index.cfm?c=28186

(Amended by Ordinance Nos. 176955 and 182053, effective August 15, 2008.) The Portland Water Bureau's goal is to provide water pressure to the property line in the range of 40 pounds per square inch (psi) to 110 psi. The State of Oregon Department of Human Services rules dictate that a water service must provide a minimum of 20 psi at the meter. Pumps, elevated reservoirs and tanks and pressure reducing valves are utilized to provide pressure in the range of 40 psi to 110 psi where possible or practical. The Bureau of Development Services, Plumbing Division, through Title 25 of the City Code, regulates pressure on private property and requires a pressure reducing device for on-site domestic water systems that receive water at greater than 80 psi.
If the pressure to the service is within the range of 20 psi to 40 psi, the water user may choose to install a booster pump system on the premises to improve the working of the private plumbing system. The property owner or ratepayer is responsible for the installation, operation and maintenance of any pressure boosting system. The addition of a booster pump will require an appropriate backflow prevention assembly be installed on the water service, on private property, and directly adjacent to the property line, as required by City Code Section 21.12.320.
The Portland Water Bureau does not guarantee that water can be provided continuously at a particular pressure or rate of flow. Varying demands on the system and the requirement to change operations affect the flow and pressure available to the service
#######

``` javascript
{
  "statute": "21.12.140",
  "requirements": {
    "water_pressure": { "value": { "minimum": 20 },
                        "units": "psi"},
    "location": "at the meter",
    "per": State of Oregon Department of Human Services"
  },
  "ideal_requirements": {
    "water_pressure": {"value": { "minimum": 40, "maximum": 110},
                       "units": "psi"},
    "location": "to property line",
    "per": "Portland Water Bureau"
  }
}
```

3. Determine if you are in compliance with the law by submitting relevant quantitative data 
   for a given statute.

   Example: Provide the requirements of Title 21 Chapter 21.12.140.