with map(subject_id, num, chapter_id) as (
  values
    ('science','1','chemical-reactions'),('science','2','acids-bases-salts'),('science','3','metals-nonmetals'),
    ('science','4','carbon-compounds'),('science','5','periodic-classification'),('science','6','life-processes'),
    ('science','7','control-coordination'),('science','8','reproduction'),('science','9','heredity-evolution'),
    ('science','10','light'),('science','11','human-eye'),('science','12','electricity'),
    ('science','13','magnetic-effects'),('science','14','energy-sources'),('science','15','our-environment'),
    ('science','16','natural-resources'),
    ('maths','1','real-numbers'),('maths','2','polynomials'),('maths','3','linear-equations'),
    ('maths','4','quadratic-equations'),('maths','5','ap'),('maths','6','triangles'),
    ('maths','7','coordinate-geometry'),('maths','8','trigonometry'),('maths','9','trig-applications'),
    ('maths','10','circles'),('maths','11','constructions'),('maths','12','areas-circles'),
    ('maths','13','surface-areas'),('maths','14','statistics'),('maths','15','probability'),
    ('sst','1','nationalism-europe'),('sst','2','nationalism-india'),('sst','3','resources'),
    ('sst','4','water-resources'),('sst','5','power-sharing'),('sst','6','federalism'),
    ('sst','7','development'),('sst','8','sectors-economy'),
    ('english','1','first-flight'),('english','2','poems'),('english','3','footprints'),
    ('english','4','grammar'),('english','5','writing'),
    ('hindi','1','kshitij-kavya'),('hindi','2','kshitij-gadya'),('hindi','3','kritika'),('hindi','4','vyakaran')
)
update public.questions q
set chapter_id = m.chapter_id, updated_at = now()
from map m
where q.subject_id = m.subject_id and q.chapter_id = m.num;

with map(subject_id, num, chapter_id) as (
  values
    ('science','1','chemical-reactions'),('science','2','acids-bases-salts'),('science','3','metals-nonmetals'),
    ('science','4','carbon-compounds'),('science','5','periodic-classification'),('science','6','life-processes'),
    ('science','7','control-coordination'),('science','8','reproduction'),('science','9','heredity-evolution'),
    ('science','10','light'),('science','11','human-eye'),('science','12','electricity'),
    ('science','13','magnetic-effects'),('science','14','energy-sources'),('science','15','our-environment'),
    ('science','16','natural-resources'),
    ('maths','1','real-numbers'),('maths','2','polynomials'),('maths','3','linear-equations'),
    ('maths','4','quadratic-equations'),('maths','5','ap'),('maths','6','triangles'),
    ('maths','7','coordinate-geometry'),('maths','8','trigonometry'),('maths','9','trig-applications'),
    ('maths','10','circles'),('maths','11','constructions'),('maths','12','areas-circles'),
    ('maths','13','surface-areas'),('maths','14','statistics'),('maths','15','probability'),
    ('sst','1','nationalism-europe'),('sst','2','nationalism-india'),('sst','3','resources'),
    ('sst','4','water-resources'),('sst','5','power-sharing'),('sst','6','federalism'),
    ('sst','7','development'),('sst','8','sectors-economy'),
    ('english','1','first-flight'),('english','2','poems'),('english','3','footprints'),
    ('english','4','grammar'),('english','5','writing'),
    ('hindi','1','kshitij-kavya'),('hindi','2','kshitij-gadya'),('hindi','3','kritika'),('hindi','4','vyakaran')
)
update public.ncert_solutions s
set chapter_id = m.chapter_id, updated_at = now()
from map m
where s.subject_id = m.subject_id and s.chapter_id = m.num;