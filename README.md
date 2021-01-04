![Spaced Repetition by Wärn](https://johanneswarn.com/spaced-repetition/github-banner.png)

Spaced Repetition by Wärn is a smallflash card based memorisation app for iOS. It uses a [Leitner system](https://en.wikipedia.org/wiki/Spaced_repetition) to decide which card to review. I made it as a gift to a friend, and it is inspired by [Nicky Case’s excellent comic about spaced repetition](https://ncase.me/remember/). The app is [available on the Apple app store](https://apps.apple.com/app/spaced-repetition-by-wärn/id1476169025).

# Basic Functionality

In the app you create cards. On the front of the card you write a question, and on the back you write the answer. In addition to writing you can draw or add pictures to either side.

Once a day the app prepares a test for you with some of the cards. The app first presents the front of the card which has the question. You then try to remember the answer that is on the back of the card. You can tap the card to flip it over and reveal the answer. You then decide wether you answered the question correctly or incorrectly.

To ensure efficient memorisation the app uses a simple spaced repetition algorithm to determine which cards to review. The basic idea of the algorithm is to double the number of days until the next time you have to review a card – each time you get that card right.

To achieve this doubling in a way that is transparent to the user a system of levels is used. Every new card starts at level 1. When you answer it correctly it is moved to level 2, and then next time to level 3, and so on. The cards in level 1 is reviewed every day, level 2 is reviewed every other day. Then level 3 is reviewed _roughly_ every fourth day, and level 4 _roughly_ every eighth day. This doubling continues until level 7 which is reviewed _roughly_ every 64 days. The reason the levels from 3 and up are reviewed on exact intervals is to ensure that no more than three levels are reviewed on any given day.

After a card in level 7 has been reviewed correctly it is moved to a special level of finished cards. You can move cards freely between levels, and could therefore (if you wanted) move a card from this level back to level 1.

If you review a card incorrectly it is moved all the way back to level 1. The current test will keep showing you this card until you get it right, and it is then moved to level 2.

If this explanation left you more confused than before I again recommend [Nicky Case’s excellent comic about spaced repetition](https://ncase.me/remember/).

# Model Layer

The model layer of the app consists of two parts: the image manager and the days completed manager.

## Image manager

The image manager stores all the cards. Initially the app was only intended to be used by me and my friend, so setting up a database felt too complicated at the time. Instead all cards are stored as two images `[card-ID]-front.png` and `[card-ID]-back.png`. These image files are organised in directories depending on which level they are currently in. This setup of course brings its own complications.

Migrating the storage of cards to a database system would make new features possible such as: voice-over, search, attached audio.

## Days completed manager

The days completed manager keeps track of which levels to review which day. It does this by storing an array of dates for completed tests in `UserDefaults`. Which levels the nth test will contain is decided by the array `levelsToRepeatAtDay`, and loops after 64 days.

If you miss a test, then it is pushed forward to the next day until you complete it. If a test would have contained no cards it is instead skipped.

# UI Layer

The app is storyboard based. As it is fairly simple there is a single storyboard, `Main.storyboard`. From then on the view controllers and views are organised by functionality.

---

While not sufficiently documented, the code is hopefully reasonably readable. If you have any questions don’t hesitate to contact me.

Best,  
Johannes Wärn