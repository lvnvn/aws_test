Sample REST API using AWS services configured with terraform. 


![schema](https://github.com/lvnvn/aws_test/blob/master/aws.png?raw=true)

---

#### Saving mood entry

`POST /mood`

##### Parameters

| name | type | data type | description |
| --- | --- | --- | --- |
| mood | required | string | N/A |
| email | required | string | N/A |

##### Responses

##### Example cURL

```plaintext
curl -X POST -d '{"mood":"happy","email":"user1@gmail.com"}' "https://232n1x2q39.execute-api.us-east-1.amazonaws.com/mood"
```

---

#### Reading mood entries

`GET /mood`

##### Parameters

| name | type | data type | description |
| --- | --- | --- | --- |
| email | not required | string | N/A |

##### Responses

##### Example cURL

```plaintext
curl -X GET "https://232n1x2q39.execute-api.us-east-1.amazonaws.com/mood"
curl -X GET "https://232n1x2q39.execute-api.us-east-1.amazonaws.com/mood?email=user@gmail.com"
```
