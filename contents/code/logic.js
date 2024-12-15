function fetchComic(date, isPrevious = false, previousComicUrl = null) {
    const baseUrl = "https://www.penny-arcade.com/comic/";
    const comicUrl = date ? `${baseUrl}${date}` : baseUrl;
    const requestUrl = isPrevious && previousComicUrl ? `${previousComicUrl}?${Date.now()}` : comicUrl; // Cache busting

    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", requestUrl);

        // Set the User-Agent to mimic a browser
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0");
        xhr.setRequestHeader("Accept", "text/html");
        xhr.setRequestHeader("Cookie", "PHPSESSID=f72l9tr0tof4frb0ml5euc7unv; _csrf=12b07e2add7af5470bb9ae32bb966c0e6475ec45ffa6dbb24c5b6b001a0dd33ea%3A2%3A%7Bi%3A0%3Bs%3A5%3A%22_csrf%22%3Bi%3A1%3Bs%3A32%3A%22hdsdlvCVEs8RtLU8vMcp1-AzqOXruksM%22%3B%7D");

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
                const previousComicUrl = olderLinkMatch ? olderLinkMatch[1] : null;

                const fullPreviousComicUrl = previousComicUrl ? `https://www.penny-arcade.com${previousComicUrl}` : null;

                console.log("Previous Comic URL:", fullPreviousComicUrl); // Add this line to check the URL

                // Extract description from <section class="post-text">
                const descriptionMatch = responseText.match(/<section class="post-text">([\s\S]*?)<\/section>/i);
                const description = descriptionMatch ? descriptionMatch[1] : null;

                // Extract all <p> elements inside the description section
                const paragraphs = description ? description.match(/<p>(.*?)<\/p>/g) : [];

                const formattedDescription = paragraphs.map(p => {
                    return p.replace(/<[^>]+>/g, '').trim();  // Remove HTML tags and trim the text
                }).join("\n\n");

                 console.log("Updated comic info", formattedDescription);

                const comicInfo = {
                    url: ogUrlMatch && ogUrlMatch[1] ? ogUrlMatch[1] : null,
                    imageUrl: ogImageMatch && ogImageMatch[1] ? ogImageMatch[1] : null,
                    title: titleMatch && titleMatch[1] ? titleMatch[1] : "Penny Arcade Comic",
                    previousComicUrl: fullPreviousComicUrl,
                    description: formattedDescription
                };


                resolve(comicInfo);

            } else {
                console.log("Failed to fetch page with status:", xhr.status);
                reject("Comic information not found");
            }

        };

        xhr.onerror = () => {
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
