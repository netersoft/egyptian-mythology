"""Draws the map of cult centres shown on the "Map" reference page.

One PNG per locale (assets/docs/res/pictures/reference/map-<locale>.png),
transparent, in the docs' gold tones so it reads on their black background.
Coordinates are real latitudes/longitudes; the projection is equirectangular.
Re-run after changing a name:  python3 tool/cult_map.py
"""
import math
from PIL import Image, ImageDraw, ImageFont

# (id, lat, lon, label side) -- side is where the label goes: 'l' or 'r'.
SITES = [
    ('bouto', 31.19, 30.74, 'r'), ('sais', 30.97, 30.77, 'r'), ('bubastis', 30.57, 31.51, 'r'),
    ('heliopolis', 30.13, 31.31, 'r'), ('giza', 29.98, 31.13, 'l'), ('memphis', 29.85, 31.25, 'r'),
    ('fayum', 29.31, 30.84, 'l'), ('hermopolis', 27.78, 30.80, 'l'), ('amarna', 27.65, 30.90, 'r'),
    ('asyut', 27.18, 31.18, 'l'), ('akhmim', 26.56, 31.75, 'r'), ('abydos', 26.18, 31.92, 'l'),
    ('dendera', 26.14, 32.67, 'r'), ('coptos', 25.99, 32.82, 'r'), ('thebes', 25.70, 32.64, 'l'),
    ('esna', 25.29, 32.55, 'l'), ('elkab', 25.12, 32.80, 'r'), ('edfu', 24.98, 32.87, 'r'),
    ('kom_ombo', 24.45, 32.93, 'r'), ('elephantine', 24.09, 32.89, 'l'), ('philae', 24.02, 32.88, 'r'),
]

NAMES = {
    'fr': dict(bouto='Bouto', sais='Saïs', bubastis='Bubastis', heliopolis='Héliopolis', giza='Gizeh', memphis='Memphis',
               fayum='Fayoum', hermopolis='Hermopolis', amarna='Amarna', asyut='Assiout', akhmim='Akhmim', abydos='Abydos',
               dendera='Dendérah', coptos='Coptos', thebes='Thèbes', esna='Esna', elkab='El-Kab', edfu='Edfou',
               kom_ombo='Kom Ombo', elephantine='Éléphantine', philae='Philae',
               sea='Mer Méditerranée', red_sea='Mer Rouge', nile='Nil', lower='BASSE-ÉGYPTE', upper='HAUTE-ÉGYPTE'),
    'en': dict(bouto='Buto', sais='Sais', bubastis='Bubastis', heliopolis='Heliopolis', giza='Giza', memphis='Memphis',
               fayum='Faiyum', hermopolis='Hermopolis', amarna='Amarna', asyut='Asyut', akhmim='Akhmim', abydos='Abydos',
               dendera='Dendera', coptos='Coptos', thebes='Thebes', esna='Esna', elkab='El Kab', edfu='Edfu',
               kom_ombo='Kom Ombo', elephantine='Elephantine', philae='Philae',
               sea='Mediterranean Sea', red_sea='Red Sea', nile='Nile', lower='LOWER EGYPT', upper='UPPER EGYPT'),
    'de': dict(bouto='Buto', sais='Sais', bubastis='Bubastis', heliopolis='Heliopolis', giza='Gizeh', memphis='Memphis',
               fayum='Fayum', hermopolis='Hermopolis', amarna='Amarna', asyut='Assiut', akhmim='Achmim', abydos='Abydos',
               dendera='Dendera', coptos='Koptos', thebes='Theben', esna='Esna', elkab='Elkab', edfu='Edfu',
               kom_ombo='Kom Ombo', elephantine='Elephantine', philae='Philae',
               sea='Mittelmeer', red_sea='Rotes Meer', nile='Nil', lower='UNTERÄGYPTEN', upper='OBERÄGYPTEN'),
    'es': dict(bouto='Buto', sais='Sais', bubastis='Bubastis', heliopolis='Heliópolis', giza='Guiza', memphis='Menfis',
               fayum='El Fayum', hermopolis='Hermópolis', amarna='Amarna', asyut='Asiut', akhmim='Ajmim', abydos='Abidos',
               dendera='Dendera', coptos='Coptos', thebes='Tebas', esna='Esna', elkab='El Kab', edfu='Edfu',
               kom_ombo='Kom Ombo', elephantine='Elefantina', philae='Filae',
               sea='Mar Mediterráneo', red_sea='Mar Rojo', nile='Nilo', lower='BAJO EGIPTO', upper='ALTO EGIPTO'),
    'pt': dict(bouto='Buto', sais='Saís', bubastis='Bubástis', heliopolis='Heliópolis', giza='Gizé', memphis='Mênfis',
               fayum='Faium', hermopolis='Hermópolis', amarna='Amarna', asyut='Assiut', akhmim='Akhmim', abydos='Abidos',
               dendera='Dendera', coptos='Coptos', thebes='Tebas', esna='Esna', elkab='El Kab', edfu='Edfu',
               kom_ombo='Kom Ombo', elephantine='Elefantina', philae='Filas',
               sea='Mar Mediterrâneo', red_sea='Mar Vermelho', nile='Nilo', lower='BAIXO EGITO', upper='ALTO EGITO'),
}

NILE = [(24.02, 32.88), (24.09, 32.89), (24.45, 32.93), (24.98, 32.87), (25.29, 32.55), (25.70, 32.64), (26.00, 32.80),
        (26.16, 32.72), (26.05, 32.25), (26.18, 31.95), (26.56, 31.72), (27.18, 31.18), (27.70, 30.88), (28.10, 30.75),
        (28.70, 30.95), (29.07, 31.10), (29.85, 31.26), (30.05, 31.23), (30.20, 31.13)]
ROSETTA = [(30.20, 31.13), (30.60, 30.90), (31.00, 30.60), (31.46, 30.37)]
DAMIETTA = [(30.20, 31.13), (30.60, 31.25), (31.00, 31.40), (31.52, 31.84)]
COAST = [(31.00, 29.00), (31.20, 29.90), (31.46, 30.37), (31.58, 30.90), (31.60, 31.30), (31.52, 31.84),
         (31.30, 32.30), (31.10, 32.60), (31.12, 33.20)]
RED_SEA_WEST = [(29.97, 32.55), (29.30, 32.65), (28.50, 33.00), (27.70, 33.70), (26.70, 34.00), (25.50, 34.60),
                (24.50, 35.20), (23.80, 35.50)]
FAYUM_LAKE = (29.47, 30.60)

LAT0, LAT1, LON0, LON1 = 23.75, 31.75, 29.0, 35.0
H = 1500
K = math.cos(math.radians(27.5))
SCALE = H / (LAT1 - LAT0)
W = int((LON1 - LON0) * K * SCALE)

TEXT = (255, 223, 0, 255)
LINE = (218, 165, 32, 255)
WATER = (64, 164, 223, 255)
FONT = ImageFont.truetype('assets/fonts/montserrat/montserrat_medium.ttf', 30)
SMALL = ImageFont.truetype('assets/fonts/montserrat/montserrat_medium.ttf', 26)
REGION = ImageFont.truetype('assets/fonts/montserrat/montserrat_bold.ttf', 30)


def xy(lat, lon):
    return ((lon - LON0) * K * SCALE, (LAT1 - lat) * SCALE)


def draw(locale):
    n = NAMES[locale]
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    d.line([xy(*p) for p in COAST], fill=LINE, width=4, joint='curve')
    d.line([xy(*p) for p in RED_SEA_WEST], fill=LINE, width=4, joint='curve')
    for course, width in ((NILE, 8), (ROSETTA, 6), (DAMIETTA, 6)):
        d.line([xy(*p) for p in course], fill=WATER, width=width, joint='curve')
    fx, fy = xy(*FAYUM_LAKE)
    d.ellipse([fx - 28, fy - 10, fx + 28, fy + 10], fill=WATER)

    d.text(xy(31.62, 29.1), n['sea'], font=SMALL, fill=WATER, anchor='ls')
    d.text(xy(26.9, 34.1), n['red_sea'], font=SMALL, fill=WATER, anchor='ls')
    d.text(xy(28.4, 31.05), n['nile'], font=SMALL, fill=WATER, anchor='lm')
    d.text(xy(30.45, 29.9), n['lower'], font=REGION, fill=LINE, anchor='mm')
    d.text(xy(26.7, 29.9), n['upper'], font=REGION, fill=LINE, anchor='mm')

    for site, lat, lon, side in SITES:
        x, y = xy(lat, lon)
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=TEXT)
        if side == 'r':
            d.text((x + 14, y), n[site], font=FONT, fill=TEXT, anchor='lm')
        else:
            d.text((x - 14, y), n[site], font=FONT, fill=TEXT, anchor='rm')

    img.save(f'assets/docs/res/pictures/reference/map-{locale}.png', optimize=True)


if __name__ == '__main__':
    for locale in NAMES:
        draw(locale)
