# Installing the Bookstore

Everything needed to run the project on a Windows 10 or 11 computer (64-bit). About 15 minutes, most of it downloads.

The project has two parts:

- **Three services** (user, book, order), which hold the data, run on this computer.
- **Two desktop apps**: **Bookstore**, for customers, and **Bookstore Manager**, for managers.

## Get the files

From the [latest release](https://github.com/KFUPMer/csce310-bookstore/releases) download:

| File | What it is |
|---|---|
| `Bookstore-Server-<version>.zip` | The services and the whole source, ready to set up |
| `Bookstore-Apps-Setup-<version>.exe` | The installer for both apps |

(`Bookstore-Apps-<version>-portable.zip` holds the same two apps, to unzip and run without installing.)

## 1. MySQL, if it is not installed yet

The only thing to install by hand. If MySQL Server 8 is already on the computer, skip this.

1. Download the **MySQL Installer for Windows** from https://dev.mysql.com/downloads/installer/
2. Choose **Server only**, and keep the defaults (port 3306, run as a Windows service).
3. Choose a root password and remember it. Setup asks for it once, in step 2.

## 2. Set up the services

1. Unzip `Bookstore-Server-<version>.zip`, for example to your Desktop.
2. In the unzipped folder, double-click **`setup.cmd`**.

It checks each part and installs what is missing: Java 21, Python 3.12, and MongoDB, through winget (Windows may ask for permission). It then creates the `bookstore` database and the test data. If anything is missing it says exactly what, and running it again continues where it stopped.

**The one question:** MySQL asks for your **MySQL root password**, once, to create the database and a limited account that the services use from then on. The password goes straight to MySQL; nothing stores it.

## 3. Start the services

Double-click **`start-services.cmd`**. Three minimized windows open, one per service. Leave them open while you use the apps. **`stop-services.cmd`** stops them.

## 4. Install the apps

Double-click **`Bookstore-Apps-Setup-<version>.exe`**. It needs no administrator rights. It adds **Bookstore** and **Bookstore Manager** to the Start menu.

Windows may warn about an "unknown publisher", because the installer is not code-signed (signing costs money). Choose **More info**, then **Run anyway**.

## 5. Log in

| App | Username | Password |
|---|---|---|
| Bookstore (customer) | `customer1` | `customer123` |
| Bookstore Manager | `manager1` | `manager123` |

You can also create a new customer account from the Bookstore login screen.

## Things to try

- **Bookstore:**
  - search as you type;
  - buy or rent books (renting costs 10% of the price, for 7 days);
  - place the order and see the bill;
  - pay it with the demonstration checkout (no card is needed);
  - open **your account** from your name in the top bar.
- **Bookstore Manager:**
  - see every order;
  - mark one as paid;
  - open its bill and print it;
  - add a book, or change one's number of copies.

## Optional: email the bills

Bills are always saved as HTML files in `services\order-service\bills`. To also email them, put a Gmail address and a Gmail [app password](https://myaccount.google.com/apppasswords) in `services\.env`, then restart the services:

```
SMTP_USER=your.address@gmail.com
SMTP_PASSWORD=the 16-letter app password
MAIL_FROM=your.address@gmail.com
```

## If something goes wrong

| What you see | What to do |
|---|---|
| The app says a service "is not answering" | Run `start-services.cmd`. If a port does not answer, restore its minimized window to read why |
| setup.cmd: "MySQL Server 8 is not installed" | Do step 1, then run setup.cmd again |
| setup.cmd: MySQL "Access denied" | The root password was mistyped; it asks up to three times. Run setup.cmd again to retry |
| start-services.cmd: "Something is already using port 8081" | Run `stop-services.cmd`, then start again |
| Anything else | `python database\check_setup.py` says whether each database is ready |

To reset the test data at any time: `python database\seed.py` in the server folder.

## Building from the source instead

For developers: the tools and versions are in [docs/05-setup/environment.md](docs/05-setup/environment.md). Run the apps with `flutter run -d windows` in `clients/customer-app` or `clients/management-app`. The release files above are built by GitHub Actions (`.github/workflows/windows-release.yml`) from the tagged commit.
