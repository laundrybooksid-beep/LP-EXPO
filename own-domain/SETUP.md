# Setup: own-domain version

`index.html` is the whole landing page in one file. Host it on your own domain, such as `seminar.berani-laundry.com`, so that Google Analytics, the Meta Pixel and UTM tags work. All three are blocked on the claude.ai artifact.

Every "Daftar" button opens WhatsApp (0811-2005-5578) with a pre-filled registration message that includes the chosen ticket. The team replies with the payment link.

## Editing

Edit `../seminar-landing.html`, then run `build.ps1` from the project folder. That regenerates `own-domain/index.html`. Don't edit `index.html` directly, or the next build will overwrite your changes.

## 1. Fill in the CONFIG block

The block is near the bottom of `seminar-landing.html`:

```js
tickets: { berani: { price: null, soldOut: false } },  // BERANI first-10 price, e.g. 250000
seatsLeft: null,  // set a number to show "Sisa N kursi"; update by hand
gaId: "",         // GA4 Measurement ID, e.g. "G-ABC123XYZ"
pixelId: ""       // Meta Pixel ID
```

**The "Spesial via BERANI" card** shows only when `berani.price` is a number above 0 and `soldOut` is `false`. With a price it shows the big price, the struck-through Rp450.000 and a "Hemat RpX" label. With no price, or with `soldOut: true` (set it when the first 10 seats are gone), the card is hidden, and the Non-member card stays alone. When several cards are available, the cheapest comes first.

## 2. Google Analytics 4

1. In analytics.google.com, go to **Admin → Data streams → Add stream → Web**. Enter your domain and copy the **Measurement ID** (`G-…`) into `gaId`. Run `build.ps1`, commit and push.
2. Keep **Enhanced measurement** on (it adds outbound clicks and its own 90% `scroll`).

### Events

| Event | Sent by | When it fires | Parameters |
| --- | --- | --- | --- |
| `page_view` | GA4 automatically | Every page load | |
| `first_visit` | GA4 automatically | A user's first visit (GA4 reserves this name; the page can't send it) | |
| `scroll_50` | Page | Half of the page has been in view, once per visit | `percent_scrolled` = 50 |
| `engaged_10sec` | Page | 10 seconds with the page visible, once per visit. Tells "left right away" (no event) from "read for a moment" (this event, but no `engaged_30sec`) | `engagement_seconds` = 10 |
| `engaged_30sec` | Page | 30 seconds with the page visible (background-tab time doesn't count), once per visit | `engagement_seconds` = 30 |
| `high_intent` | Page | Once both `scroll_50` and `engaged_30sec` have fired in the same visit | `trigger`; also sets the user property `high_intent_user` = `yes` |
| `begin_checkout` | Page | A tap on a "Daftar via WhatsApp" button (initiate checkout) | `currency` IDR, `value` (ticket price), `items`, `ticket`, `cta_location`, `method` = whatsapp |
| `whatsapp_question` | Page | A tap on "Tanya dulu" (also WhatsApp, but a question, not a registration) | `ticket` = question, `cta_location`, `method` |
| `hipli_member_click` | Page | A tap on "Saya member HIPLI". Its own event, not a checkout: members get their link from the team | `ticket` = member, `cta_location`, `method` |
| `view_tickets` | Page | The tickets section scrolls into view, once per visit | |
| `faq_open` | Page | An FAQ question is opened | `question` |
| `open_maps` | Page | A tap on the Google Maps link | |

`begin_checkout` and `whatsapp_question` are two separate paths, not steps of one funnel.

`cta_location` says which button was tapped: `nav`, `hero`, `mid_tentang`, `mid_materi`, `mid_pembicara`, `mid_kegiatan`, `tiket_berani`, `tiket_umum`, `tiket_hipli`, `faq`, `footer`, `sticky_bar`. The `mid_*` values are the compact CTA blocks between sections; `mid_tentang` and `mid_kegiatan` were added so no stretch of the page goes more than about 1,600 px without a register button.

### One-time setup in GA4 Admin

1. **Key events:** Admin → Events (or Key events) → mark `begin_checkout` and `high_intent` as key events. Events only appear in this list after they've been received once, so do this after the test below.
2. **Custom definitions:** Admin → Custom definitions → Create custom dimension:
   - Scope **User**, user property `high_intent_user`
   - Scope **Event**: `cta_location`, `ticket`, `trigger`
3. **"High intent user" audience:** Admin → Audiences → New audience → Create a custom audience:
   - Name: `High intent user`
   - Condition: Event `high_intent` (or user property `high_intent_user` exactly matches `yes`)
   - Membership duration: 30 days (or what fits your remarketing)

   This audience can be linked to Google Ads for remarketing. It only collects people from the moment it's created.
4. **Funnel (optional):** Explore → Funnel exploration with steps `page_view` → `engaged_10sec` → `engaged_30sec` → `high_intent` → `begin_checkout`. Don't put `whatsapp_question` or `hipli_member_click` in the same funnel: they are separate paths. Break the report down by the `cta_location` dimension to see which button gets the taps.

## 3. Meta Pixel

Pixel `1418822797097429` is set in `pixelId`. The page sends:

| Meta event | Type | When |
| --- | --- | --- |
| `PageView` | standard | Every page load |
| `InitiateCheckout` | standard | A tap on a "Daftar via WhatsApp" button, with `value` (ticket price), `currency` IDR and `cta_location` |
| `Contact` | standard | A tap on "Tanya dulu", with `cta_location` |
| `hipli_member_click` | custom | A tap on "Saya member HIPLI", with `cta_location` |
| `scroll_50` | custom | Half of the page in view, once per visit |
| `engaged_10sec` | custom | 10 seconds with the page visible, once per visit |
| `engaged_30sec` | custom | 30 seconds with the page visible, once per visit |
| `high_intent` | custom | `scroll_50` and `engaged_30sec` in one visit |

To optimize ads for registrations, use `InitiateCheckout`. For retargeting, create a Custom Audience in Meta Ads Manager → Audiences → Create audience → Custom audience → Website → event `high_intent`. Custom events show up in Events Manager after the first one is received; to use one as an optimization goal, create a Custom Conversion from it (Events Manager → Custom conversions).

## 4. Ad URLs

Give each ad its own `utm_content`:

```
https://seminar.berani-laundry.com/?utm_source=meta&utm_medium=paid&utm_campaign=seminar-14nov&utm_content=poster-a
```

GA4 reads these tags automatically. The page also adds `Kode: poster-a` to the end of the WhatsApp message, so the team can see which ad brought each chat.

## 5. Host it

**Netlify (connected to the GitHub repo):** `netlify.toml` at the repo root tells Netlify to publish the `own-domain` folder, so every push to `main` redeploys the page. Run `build.ps1` and commit the updated `own-domain/index.html` before pushing; Netlify does not run the build.

Other options: Netlify Drop (drag the `own-domain` folder in), Cloudflare Pages, Vercel, or your existing cPanel.

## 6. Test before ads go live

1. Open the page with the test URL above plus `&ga_debug=1` at the end. That turns on GA4 DebugView for your visit and prints every event in the browser console as `[ga4] …`.
2. In GA4 **Admin → DebugView**, check that `page_view` arrives.
3. Scroll past the middle of the page and stay 30 seconds: `scroll_50`, `engaged_30sec` and then `high_intent` should arrive.
4. Tap "Daftar via WhatsApp". WhatsApp should open with the message filled in and ending in `Kode: poster-a`, and `begin_checkout` should appear.
5. In Meta Events Manager → Test events, check that `PageView` and `InitiateCheckout` arrive.

## Daily routine

Every WhatsApp registration starts a checkout. The team replies with the payment link the same day. Anyone who doesn't pay within 24 hours gets one follow-up message. Compare the GA4 `begin_checkout` count with the chats you received and the payments you've confirmed.
