# Setup: own-domain version

`index.html` is the whole landing page in one file. Host it on your own domain, such as `seminar.berani-laundry.com`, so that Google Analytics, the Meta Pixel and UTM tags work. All three are blocked on the claude.ai artifact.

Every "Daftar" button opens WhatsApp (0811-2005-5578) with a pre-filled registration message that includes the chosen ticket. The team replies with the payment link.

## Editing

Edit `../seminar-landing.html`, then run `build.ps1` from the project folder. That regenerates `own-domain/index.html`. Don't edit `index.html` directly, or the next build will overwrite your changes.

## 1. Fill in the CONFIG block

The block is near the bottom of `seminar-landing.html`:

```js
tickets: { berani: { price: null } },  // BERANI first-10 price, e.g. 250000
seatsLeft: null,  // set a number to show "Sisa N kursi"; update by hand
gaId: "",         // GA4 Measurement ID, e.g. "G-ABC123XYZ"
pixelId: ""       // Meta Pixel ID
```

Also replace the speaker photo placeholders, marked `TODO: Nirwan`, with `<img src="nirwan.jpg" alt="Nirwan">`, and upload the image next to `index.html`.

## 2. Google Analytics 4

1. In analytics.google.com, go to **Admin → Data streams → Add stream → Web**. Enter your domain and copy the **Measurement ID** (`G-…`) into `gaId`.
2. Keep **Enhanced measurement** on. It tracks page views, scroll depth and outbound clicks automatically.
3. The page also sends these events:

| Event | When it fires | Parameters |
| --- | --- | --- |
| `generate_lead` | A tap on any "Daftar via WhatsApp" or "Minta link member" button | `cta_location` (nav, hero, sticky, ticket_berani, ticket_nonmember, member_note, final), `ticket`, `value`, `currency` |
| `whatsapp_question` | A tap on "Tanya dulu" | `cta_location` |
| `view_tickets` | The tickets section scrolls into view (once per visit) | none |
| `faq_open` | An FAQ question is opened | `question` |
| `open_maps` | A tap on the Google Maps link | none |

4. In **Admin → Events**, mark `generate_lead` as a **key event**, so it shows up as a conversion.
5. To see which ad drives registrations, use the report **Reports → Engagement → Events → generate_lead**, broken down by *Session source / medium* and *Session manual ad content*.
6. To make `cta_location` and `ticket` show up in reports, register them under **Admin → Custom definitions → Create custom dimension** (scope: Event).

## 3. Meta Pixel

Put the Pixel ID in `pixelId`. The page fires `PageView` on load, `Lead` on a registration tap and `Contact` on a question tap. To optimize ads for registrations, use `Lead`.

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

1. Open the page with the test URL above.
2. In GA4 **Admin → DebugView**, or the Realtime report, check that `page_view` arrives.
3. Tap "Daftar via WhatsApp". WhatsApp should open with the message filled in and ending in `Kode: poster-a`, and `generate_lead` should appear in Realtime.
4. In Meta Events Manager → Test events, check that `PageView` and `Lead` arrive.

## Daily routine

Every WhatsApp registration is a lead. The team replies with the payment link the same day. Anyone who doesn't pay within 24 hours gets one follow-up message. Compare the GA4 `generate_lead` count with the chats you received and the payments you've confirmed.
