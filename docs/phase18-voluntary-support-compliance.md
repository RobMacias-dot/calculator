# Phase 18 — voluntary support policy assessment

Reviewed 2026-10-16. **PENDING OWNER / GOOGLE PLAY POLICY REVIEW**. This is an evidence-based engineering assessment, not Google approval.

## Product and proposed journey

Engineering Toolkit, by independent software developer RobMac Software, remains permanently free. No paid calculators, subscriptions, tiers, features, donor content, badges or rewards. Contributions are optional and confer no digital goods, services, privileges or app benefits. No ads, accounts, analytics, backend or payment SDK is introduced.

Settings → About → Support Development → external browser at https://robmacsoftware.github.io/support/ → website language/provider selection → provider checkout:

- PayPal (owner-designated international/USD): https://www.paypal.com/ncp/payment/CKD4M9EU2QCD2
- Mercado Pago (owner-designated Mexico/MXN): https://link.mercadopago.com.mx/robmacsoftware

Provider URLs are supplied by the owner and unchanged. They are absent from application code. Prior owner verification covers opening checkout and observing selectable amounts only; it does not establish successful payments, settlement, recipient eligibility or universal availability. No transaction was attempted during this work.

## Official policy evidence

Sources accessed 2026-10-16:

- [Payments FAQ, direct tips/contributions](https://support.google.com/googleplay/android-developer/answer/10281818): the peer-to-peer exception requires the entire contribution to reach the creator and no digital content/services in return, including badges. Otherwise billing requirements apply. Regional options have separate conditions.
- [Payments policy, sections 2–4 and 8–9](https://support.google.com/googleplay/android-developer/answer/9858738): digital access payments generally require Play billing. Peer-to-peer payments and tax-exempt donations are separate exceptions. Restrictions cover buttons, links and flows leading to other payment methods. Regional programs require eligibility and enrollment.

## Assessment of this specific model

The no-benefit condition is supported by the implementation and permanent product decision. This is necessary but does not establish the other conditions. RobMac Software is a commercial developer brand; no charitable registration or tax exemption is established. Do not use the charitable-donation exception.

Whether this brand's actual merchant recipient qualifies as the creator for direct user-to-creator contributions is unresolved. The reviewed sources do not conclusively settle this account's status or how ordinary processor fees affect the 100% condition. Do not infer that processor deductions are allowed, prohibited, or absent. Confirm gross contribution, fees, net settlement, intermediary/platform shares and recipient identity with the owner/providers and obtain Google clarification where needed. Never advertise 100% net proceeds without verified evidence.

An intermediate official website does not establish an exemption: the entire app-to-checkout journey remains relevant. A free app and absence of benefits alone are insufficient grounds for PASS. Risk of rejection remains if Google classifies the recipient/model outside the peer-to-peer exception or finds prohibited external payment navigation.

Regional billing/link programs (including EEA/US options and alternative billing in supported regions such as India/South Korea) are not a universal permission for this flow. No enrollment, account eligibility or territory coverage was verified. No regional workaround or billing integration is implemented.

## Owner confirmations and release alternatives

Before distribution, confirm merchant legal identity and creator relationship, account eligibility, fee treatment, absence of revenue splitting, terms presented on both checkouts, and that website copy promises no digital consideration. Seek a Play policy determination for the complete journey if eligibility remains ambiguous. Retain dated evidence and recheck current policy before submission.

If the link is not permitted, release a separately reviewed app revision removing the Support Development entry and associated solicitation. The free calculators can remain available without this flow. Another path is deferring the release until policy eligibility is resolved. Any billing or regional-program proposal requires a separately approved product change consistent with the permanent free-software decision.

## Final publication gate

**BLOCKED — SUPPORT WEBSITE NOT YET PUBLISHED**: both reserved support pages returned HTTP 404 on 2026-10-16. Publish/audit the website and bilingual privacy amendments separately, then validate the actual journey on-device without a real payment. Owner/Google policy review must resolve the conditions above before claiming eligibility. Signing, final AAB, 16 KB/device and Console gates also remain open. A passing widget test or browser-launch result does not establish policy approval or a working website.
