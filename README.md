# rssfeed

RSS Feed JSON

## Json file details

The JSON file can be found under `$ENV:UserProfile\rssfeed\rssfeed.json`

```json
{
  "auth": "",
  "description": null,
  "rssfeeds": [
    {
      "Name": "windows test1",
      "URI": "https://twit.memberfulcontent.com/rss/8899",
      "Interval": "60 * 60 * 24"
    }
  ]
}
```

> [!NOTE]
> Interval is not used at this time.

## Create a new json file

```powershell
New-RSSJson -Name "My Feed" -URI "https://example.com/rss" -Interval 3600 -Auth "myToken"
```
