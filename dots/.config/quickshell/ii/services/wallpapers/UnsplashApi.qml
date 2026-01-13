pragma Singleton
import QtQuick
import Quickshell.Io

Singleton {
    id: root

    property string providerName: "unsplash"
    property string baseUrl: "https://api.unsplash.com"
    property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}

    function request(tags, limit, page, onSuccess, onError) {
        const apiKey = apiKeys.wallpapers_unsplash
        if (!apiKey) {
            onError?.("Unsplash API key not set. Use /api YOUR_KEY")
            return
        }

        const query = tags.join(" ")
        const perPage = Math.min(limit, 30)

        const url =
            `${baseUrl}/search/photos` +
            `?query=${encodeURIComponent(query)}` +
            `&page=${page}` +
            `&per_page=${perPage}` +
            `&orientation=landscape`

        console.debug("[Unsplash] Request:", url)

        const xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.setRequestHeader("Authorization", "Client-ID " + apiKey)
        xhr.setRequestHeader("Accept-Version", "v1")

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return

            if (xhr.status !== 200) {
                console.warn("[Unsplash] Error", xhr.status, xhr.responseText)
                onError?.(`Unsplash error ${xhr.status}`)
                return
            }

            try {
                const data = JSON.parse(xhr.responseText)

                const images = data.results.map(photo => ({
                    id: photo.id,

                    // REQUIRED BY YOUR UI
                    file_url: photo.urls.full,
                    preview_url: photo.urls.small,
                    aspect_ratio: photo.width / photo.height,
                    source: photo.links.html,
                    is_nsfw: false,

                    // Attribution (important)
                    author: photo.user.name,
                    attribution: `Photo by ${photo.user.name} on Unsplash`
                }))

                onSuccess?.([{
                    provider: "unsplash",
                    page: page,
                    tags: tags,
                    message: "",
                    images: images
                }])
            } catch (e) {
                console.error("[Unsplash] Parse error", e)
                onError?.("Failed to parse Unsplash response")
            }
        }

        xhr.send()
    }
}
