# Khosraw-AbacabaCOVID19

A fork of the repository for Abacaba's COVID-19 visualizations. Here's a playlist of those
videos: https://www.youtube.com/user/1abacaba1/videos

This Github repo was announced and explained in this video, from 2021-06-25: https://www.youtube.com/watch?v=dkbNXQFc4Ro

These visualizations all use Processing 3 to draw the actual visualization videos: https://processing.org/  If you'd
like to run these code snippets and save them to a video file, you'll also need "Hamoid's Video Exporter", a library
that allows to export directly to .mp4 video files from within Processing. Here is a demonstration of me downloading and
using the Hamoid library: https://www.youtube.com/watch?v=ol6PM0BMjzI&list=PLsRQr3mpFF3Khoca0cXA8-_tSloCwlZK8&index=10
A handful of visualizations also have Python scripts to do non-video related tasks, like sound processing.

Watch this video for a brief explanation about what this repo is: [video is not out yet]

Note: Abacaba programmed most of these visualizations quickly, as soon as data was posted to worldometers.info, since he
wanted to give the public the most up-to-date summaries as possible. As a result, none of the code is really designed
with ease-of-use, coding style, or collaborator-friendliness in mind. That's why you might find that his code seems very
hard to understand or tweak, and he apologizes for that. However, He won't be regularly maintaining this code or
providing coding assistance to new programmers for this project. This repo is supposed to be a dumping ground of his
personal projects, that just happens to be public, in case people are curious!

Also: The data-visualization called "GapMinder Inspired" is designed to collect up-to-date data in an easy way. As in,
there is a single Python script that reads the data from worldometers.com, assuming that website doesn't drastically
update in the future (after 2021-06-21). Watch the above video for a demonstration on how to run it. For all the other
data-visualizations, there is simply a data file (perhaps called something like "worldData.csv", that he downloaded and
compiled at the time, but is frozen in time (meaning, it won't update). You're free to update/change these as you wish,
but it will take a bit of work on your end, since there isn't any "data-collecting" script for those!

# China Dot Map

Seen at 3:14 in the 2020-02-28 video: https://www.youtube.com/watch?v=9PYKYjkqnGU&t=194s

![China Dot Map Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/chinaDotMap/chinaDotMapPreview.png?raw=true)

# Country Flu

Compares the COVID-19 death toll with the death tolls of other causes (like car crashes, influenza, etc.) specifically
in one country.

Note: By editing the first few lines of the source code, this data visualizer can show data from other countries, such
as India.

Seen at 11:30 in the 2020-05-31 video: https://www.youtube.com/watch?v=b1hRKhHhOF4&t=690s

![Country Flu Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/countryFlu/countryFluPreview.png?raw=true)

# Falling Piles

Seen at 2:51 in the 2020-04-02 video: https://www.youtube.com/watch?v=sz1bGzYdRdk&t=171s

Seen at 0:00 in the 2020-04-10 video: https://www.youtube.com/watch?v=x_wZQ8fVIwQ

![Falling Piles Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/fallingPiles/fallingPilesPreview.png?raw=true)

# Floating Bubble

Seen at 4:42 in the 2020-02-12 video: https://www.youtube.com/watch?v=6dDD2tHWWnU&t=282s

Seen at 1:30 in the 2021-01-21 video: https://www.youtube.com/watch?v=i7SNyzmKXUE&t=90s

![Floating Bubble Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/floatingBubble/floatingBubblePreview.png?raw=true)

# Gapminder Inspired

Inspired by Hans Rosling's work with scatter plot visualizations at Gapminder: https://www.gapminder.org/

Seen at 0:17 in the 2020-11-07 video: https://www.youtube.com/watch?v=eeiguFaRil0&t=17s

Seen at 2:27 in the 2021-01-21 video: https://www.youtube.com/watch?v=i7SNyzmKXUE&t=2m27s

getCountryList.py will scrape worldometers.com and save a list of all countries. You don't need to ever run this,
because countryList.tsv is in the repo.

Running getData.py will download the most recent international data of COVID-19 cases and deaths from worldometers.com,
and processData.py will process it into one compact file that the Processing visualizer can interpret. Check out and
modify the first few lines of both Python files to allow those scripts to download US state data instead of country
data.

![Gapminder Inspired Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/gapminderInspired/gapminderInspiredPreview.png?raw=true)

# Korea USA

Seen at 0:00 in the 2020-06-29 video: https://www.youtube.com/watch?v=3HHOK1gNypE

![Korea USA Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/koreaUSA/koreaUSApreview.png?raw=true)

# Line Graph

Seen many times. One of the first times was at 1:09 in the 2020-03-19
video: https://www.youtube.com/watch?v=n4no04822NQ&t=69s

One of the more recent times is at 0:17 in the 2021-01-20 video: https://www.youtube.com/watch?v=i7SNyzmKXUE&t=17s

![Line Graph Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/lineGraph/lineGraphPreview.png?raw=true)

# Livestream (BROKEN)

Note: You won't be able to get this code to run. Here was how the code was originally supposed to work: You run
scraper.py in one command prompt, which loads the worldometers.com/coronavirus website every 60 seconds looking for
updates. Simultaneously, you run visualizer.py in another command prompt, which reads from the dataStream.txt file that
scraper.py outputs, and turns that data into a 30 FPS video output that can then be livestreamed. However, when I try to
run this code these days, I get a 403 Forbidden error from worldometers. This probably means none of you will be able to
get the livestream up and working, either. I'm only including this code here in case anybody is curious in my coding
style/process/workflow, but not necessarily seeing it work in action.

Seen in the 2020-03-21 livestream: https://www.youtube.com/watch?v=nmrhTEwAqD0

Also seen in the 2020-03-21 livestream: 2020-03-25: https://www.youtube.com/watch?v=u35rna7XvEA

![Livestream (BROKEN) Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/livestreamBROKEN/livestreamBROKENpreview.png?raw=true)

# Mask Trendline

Seen at 0:00 in the 2021-01-10 video: https://www.youtube.com/watch?v=x7KYJ1MFGdc

![Mask Trendline Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/maskTrendline/maskTrendlinePreview.png?raw=true)

# Nervous Emoji

Note: This visualization seems to downplay the severity of the virus, which he now regrets. At the time of making it (
Feb 12, 2020), there had been 2 deaths outside China. He was worried that people were treating this outbreak the same
way they had the 2014 Ebola outbreak, which was panic and xenophobia. So, he was trying to provide a more levelled
perspective to convey to people to not overreact. However, in hindsight, this visualization made the virus seem less
deadly than it truly became, which was my mistake. He posted this code in the spirit of open-sourcing everything, but he
hope people don't use it to downplay the virus further. (If the code is edited to show recent data, it should accurately
reflect how serious it is.)

Seen at 5:44 in the 2020-02-12 video: https://www.youtube.com/watch?v=6dDD2tHWWnU&t=344s

![Nervous Emoji Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/nervousEmoji/nervousEmojiPreview.png?raw=true)

# USA Flu

Compares the COVID-19 death toll in the United States with the death tolls of other causes (like car crashes, influenza,
etc.). It is also aligned to see October 1 as the start of each year, because October 1 is the start of the "flu season"
. The goal is to see if COVID-19's trends fits in with the pattern of annual flu waves, and it does not.

Seen at 6:27 in the 2020-05-31 video: https://www.youtube.com/watch?v=b1hRKhHhOF4&t=387s

![USA Flu Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/USAflu/USAfluPreview.png?raw=true)

# With Guzheng

Seen at 0:00 in the 2020-03-08 video: https://www.youtube.com/watch?v=KrgYEdb-Fls

![With Guzheng Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/withGuzheng/withGuzhengPreview.png?raw=true)

# With Guzheng Sound

Heard at 0:00 in the 2020-03-08 video: https://www.youtube.com/watch?v=KrgYEdb-Fls

Note: chinaCOVID19deathCount.txt is a timetable describing all the times that a guzheng sound should play (in 44,000 Hz
samples) If you run coronasounder.py, it will read that timetable, and use the 6 sounds in the "sounds" folder to play a
Guzheng sound at each time interval listed! Also, sometimes, Windows Media Player is unable to play the output file.
When that happens, I just load the .wav file successfully in Audactiy (https://www.audacityteam.org/), and then save it
as a new file.

![With Guzheng Sound Preview](https://github.com/carykh/AbacabaCOVID19/blob/main/withGuzhengSound/withGuzhengSoundPreview.png?raw=true)
