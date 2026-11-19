-- Beijing x Chongli trip page — small follow-up (run once, 5 seconds)
-- Lets a person take back their own vote (tap the same button twice).
-- Nothing else changes. Safe to run twice.

grant delete on public.trip_votes to anon, authenticated;

drop policy if exists trip_votes_delete on public.trip_votes;
create policy trip_votes_delete on public.trip_votes for delete using (true);

notify pgrst, 'reload schema';
