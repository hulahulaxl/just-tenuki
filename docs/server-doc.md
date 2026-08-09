we use the kata1-b18c384nbt-s9996604416-d4316597426.bin.gz model by default.

`katago gtp -model 'kata1-b18c384nbt-s9996604416-d4316597426.bin.gz' -config 'analysis.cfg'`
`katago analysis -model kata1-b18c384nbt-s9996604416-d4316597426.bin.gz -config analysis.cfg`

test:

```
{"id":"test1","rules":"japanese","boardXSize":19,"boardYSize":19,"moves":[["B","Q4"],["W","D4"]],"analyzeTurns":[2],"maxVisits":100}
```
