## エンドポイント

### GET /point/{stream | chunk | paging-offset | paging-last }/:username

指定したユーザーのpointを取得する

### Response

200

```ts
interface Response {
  "point": number
  "time": number /* [ms] */
}
```



