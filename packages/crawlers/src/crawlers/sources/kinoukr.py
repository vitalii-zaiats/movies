"""kinoukr.tv listing pages.

Each entry looks like:

    <div class="short clearfix with-mask">
      <div class="short-img img-box">
        <img src="/uploads/mini/short/..." alt="Title">
      </div>
      <div class="short-text">
        <a class="short-title" href="https://kinoukr.tv/9136-marave.html">Title</a>
      </div>
    </div>
"""

from urllib.parse import urljoin

from bs4 import BeautifulSoup

from crawlers.models import Item
from crawlers.source import Source, register

BASE = "https://kinoukr.tv/"
CARD_SELECTOR = "div.short.clearfix.with-mask"


@register
class Kinoukr(Source):
    name = "kinoukr"

    def page_url(self, number: int) -> str:
        return urljoin(BASE, f"page/{number}/")

    def parse(self, html: str) -> list[Item]:
        soup = BeautifulSoup(html, "lxml")
        items = []

        for card in soup.select(CARD_SELECTOR):
            link = card.select_one("a.short-title")
            if link is None or not link.get("href"):
                continue

            image = card.select_one(".short-img img")
            poster = image.get("src") if image else None
            title = link.get_text(strip=True) or (image.get("alt", "") if image else "")

            items.append(
                Item(
                    title=title,
                    # Resolve against BASE, not the response URL: page 1 redirects
                    # to http://kinoukr.tv/home/ and would drag links back to http.
                    url=urljoin(BASE, str(link["href"])),
                    poster=urljoin(BASE, str(poster)) if poster else None,
                )
            )

        return items
