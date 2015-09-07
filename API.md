#API conventions

##retrieve resources list

### request:
```
GET /things?limit=10&offset=0
```

### response:

HTTP STATUS: `200`

body:
```
{
  "items": [
    {
      "id": 1,
      "name": "table"
    },
    {
      "id": 2,
      "name": "chair"
    }
  ],
  "limit": 10,
  "offset": 0,
  "count": 2,
}
```

##retrieve single resource

### request:
```
GET /things/:id
```

### response:

HTTP STATUS: `200`

body:
```
{
  "item": {
    "id": 1,
    "name": "table"
  }
}
```

##update resource

### request:
```
PUT /things/:id
```

parameters:
```
{
  "item": {
    "id": 1,
    "name": "table"
  }
}
```
### response:

success:
HTTP STATUS: `204`

body:
```
```

error:
HTTP STATUS: `400`

body:
```
{
  "errors": {
    "fieldname": "too short",
    "otherfield": "I don't like it"
  }
}
```

##create resource

### request:
```
POST /things
```

parameters:
```
{
  "item": {
    "name": "white board"
  }
}
```
### response:

success:
HTTP STATUS: `201`

error:
HTTP STATUS: `400`

body:
```
{
  "errors": {
    "fieldname": "too short",
    "otherfield": "I don't like it"
  }
}
```


##delete resource

### request:
```
DELETE /things/:id
```

### response:

success:
HTTP STATUS: `204`

error:
HTTP STATUS: `400`

body:
```
{
  "errors": {
    "generic": "can't do it"
  }
}
```
