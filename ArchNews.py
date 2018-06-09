import urllib.request
import xmltodict

def arch_news_updates():
    url = 'https://www.archlinux.org/feeds/news/'
    file = urllib.request.urlopen(url)
    data = file.read()
    file.close()

    arch_news = xmltodict.parse(data)
    
    for post in arch_news['rss']['channel']['item']:
            print("Title: ", post['title'])
            print("Date: ", post['pubDate'])
            print("Description: ", post['description'])
            print("\n")

arch_news_updates()