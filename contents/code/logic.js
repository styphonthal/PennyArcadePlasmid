function checkForNewComicDaily() {
    const today = new Date().toISOString().split("T")[0]; // Get today's date in YYYY-MM-DD format

    if (currentDate !== today) { // If the current comic is not for today
        console.log("A new comic may be available. Loading today's comic...");
        fetchComic("", false, null); // Fetch the comic for today (without specifying a date, it will default to today's comic)
    } else {
        console.log("Today's comic is already loaded.");
    }
}

function fetchComic(date, isPrevious = false, previousComicUrl = null, isNext = false) {
    // Build the URL using the provided date in YYYY/MM/DD format
    const baseUrl = "https://www.penny-arcade.com/comic/";
    const comicUrl = date ? `${baseUrl}${date}` : baseUrl;

    // Decide which comic to fetch based on previous/next flag
    let requestUrl = comicUrl;
    console.log("First step fetchcomic requesturl is", requestUrl);

    if (isPrevious && previousComicUrl) {
        requestUrl = `${previousComicUrl}?${Date.now()}`;  // Cache busting
    } else if (isNext && previousComicUrl) {
        // Extract the next comic URL from the page (if available)
        const newerLinkMatch = previousComicUrl.match(/<a class="orange-btn newer" href="([^"]+)"/i);
        if (newerLinkMatch) {
            requestUrl = `https://www.penny-arcade.com${newerLinkMatch[1]}?${Date.now()}`;  // Full URL for next comic
        } else {
            requestUrl = comicUrl;  // Fallback to current comic if no next comic is found
            console.log("FAILED TO GET NEWERLINKMATCH");
        }
    }
    console.log("BEFORE GETTING IMAGE Request URL:", requestUrl);  // Log the URL

    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", requestUrl);

        // Set the User-Agent to mimic a browser
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.setRequestHeader("Accept", "text/html");


        xhr.onload = () => {
            console.log(`Status: ${xhr.status}`);
            console.log(`Response Text: ${xhr.responseText.slice(0, 200)}...`);

            if (xhr.status === 200) {
                const responseText = xhr.responseText;
                const ogUrlMatch = responseText.match(/<meta property="og:url" content="([^"]+)"/i);
                const imgSrcMatch = responseText.match(/<img[^>]*src="([^"]+)"[^>]*>/i);
                const titleMatch = responseText.match(/<meta property="og:title" content="([^"]+)"/i);
                const ogImageMatch = responseText.match(/<meta property="og:image" content="([^"]+)"/i);

                const olderLinkMatch = responseText.match(/<a class="orange-btn older" href="([^"]+)"/i);
                const fullPreviousComicUrl = olderLinkMatch ? `https://www.penny-arcade.com${olderLinkMatch[1]}` : null;

                // Get the "newer" (next) comic URL
                const newerLinkMatch = responseText.match(/<a class="orange-btn newer" href="([^"]+)"/i);
                const fullNextComicUrl = newerLinkMatch ? `https://www.penny-arcade.com${newerLinkMatch[1]}` : null;

                console.log("Previous Comic URL:", fullPreviousComicUrl);  // Log extracted previous comic URL
                console.log("Next Comic URL:", fullNextComicUrl);  // Log extracted next comic URL

                // Extract description
                const descriptionMatch = responseText.match(/<section class="post-text">([\s\S]*?)<\/section>/i);
                const description = descriptionMatch ? descriptionMatch[1] : null;
                const paragraphs = description ? description.match(/<p>(.*?)<\/p>/g) : [];
                const formattedDescription = paragraphs.map(p => p.replace(/<(?!\/?p\b)[^>]+>/g, '').trim()).join("\n\n");

                const comicInfo = {
                    url: ogUrlMatch && ogUrlMatch[1] ? ogUrlMatch[1] : null,
                    imageUrl: ogImageMatch && ogImageMatch[1] ? ogImageMatch[1] : null,
                    title: titleMatch && titleMatch[1] ? titleMatch[1] : "Penny Arcade Comic",
                    previousComicUrl: fullPreviousComicUrl,
                    nextComicUrl: fullNextComicUrl,  // Include the next comic URL
                    description: formattedDescription
                };

                resolve(comicInfo);
            } else {
                console.log("Failed to fetch page with status:", xhr.status);
                reject("Comic information not found");
            }
        };

        xhr.onerror = () => {
            console.log("Error during the request");
            reject("Network error");
        };

        xhr.send();
    });
}



function loadPreviousComic() {
    console.log("Attempting to load previous comic...");
    if (previousComicUrl) {  // Use the stored previous comic URL
        // Fetch the previous comic using the previousComicUrl
        Logic.fetchComic("", true, previousComicUrl).then((previousComic) => {
            console.log("Fetched previous comic:", previousComic);
            currentImage = previousComic.imageUrl;
            currentTitle = previousComic.title;
            currentDate = previousComic.url.split("/").pop();  // Extract date from URL
            console.log("Updated comic info - image:", currentImage);
            console.log("Updated comic info - title:", currentTitle);
        }).catch((error) => {
            console.log("Error loading previous comic:", error);
        });
    } else {
        console.log("No previous comic URL found.");
    }
}
