-- Seed data for achievements
INSERT INTO achievements (id, name, description, category, icon, threshold_value) VALUES
-- Territory achievements
('territory_first',      '初めての陣地',         '初めてセルを獲得した',           'territory', 'flag.fill',            1),
('territory_10',         '開拓者',              '10セル獲得',                  'territory', 'map.fill',            10),
('territory_100',        '領主',                '100セル獲得',                 'territory', 'crown.fill',         100),
('territory_500',        '大名',                '500セル獲得',                 'territory', 'shield.fill',        500),
('territory_1000',       '将軍',                '1000セル獲得',                'territory', 'star.fill',         1000),
('territory_override',   '侵略者',              '初めて他ユーザーのセルを奪取',     'territory', 'flame.fill',           1),

-- Streak achievements
('streak_3',             '三日坊主突破',          '3日連続ランニング',             'streak',    'flame.fill',           3),
('streak_7',             '一週間の習慣',          '7日連続ランニング',             'streak',    'flame.fill',           7),
('streak_14',            '二週間の継続',          '14日連続ランニング',            'streak',    'flame.fill',          14),
('streak_30',            '鉄人',                '30日連続ランニング',            'streak',    'bolt.fill',           30),
('streak_100',           '修行僧',              '100日連続ランニング',           'streak',    'bolt.fill',          100),

-- Distance achievements
('distance_10km',        '初心者ランナー',        '累計10km走破',               'distance',  'figure.run',          10000),
('distance_50km',        'ジョガー',             '累計50km走破',               'distance',  'figure.run',          50000),
('distance_100km',       'ランナー',             '累計100km走破',              'distance',  'figure.run',         100000),
('distance_500km',       'マラソニスト',          '累計500km走破',              'distance',  'figure.run',         500000),
('distance_1000km',      'ウルトラランナー',       '累計1000km走破',             'distance',  'figure.run',        1000000),
('distance_single_5km',  '5キロ完走',            '1回のランで5km走破',           'distance',  'figure.run',           5000),
('distance_single_10km', '10キロ完走',           '1回のランで10km走破',          'distance',  'figure.run',          10000),
('distance_single_21km', 'ハーフマラソン',        '1回のランで21.1km走破',        'distance',  'figure.run',          21100),
('distance_single_42km', 'フルマラソン',          '1回のランで42.195km走破',      'distance',  'figure.run',          42195),

-- Social achievements
('social_team_create',   'ギルドマスター',        'チームを作成した',             'social',    'person.3.fill',        1),
('social_team_join',     '仲間入り',             'チームに参加した',             'social',    'person.badge.plus',    1);
