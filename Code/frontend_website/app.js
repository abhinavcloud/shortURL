// Replace this with your actual AWS API Gateway Endpoint
const API_ENDPOINT = "https://your-api-id.execute-api.region.amazonaws.com/prod/projects";

async function fetchGallery() {
    const container = document.getElementById('product-container');

    try {
        // 1. Fetch the JSON data from your backend (Lambda/DynamoDB)
        const response = await fetch(API_ENDPOINT);

        if (!response.ok) throw new Error("Network response was not ok");

        const data = await response.json();

        // 2. Clear the "Loading..." message
        container.innerHTML = '';

        // 3. Loop through your data and build the HTML elements
        data.forEach(item => {
            const projectCard = document.createElement('div');
            projectCard.className = 'project-card';

            projectCard.innerHTML = `
                <div class="image-wrapper">
                    <img src="${item.imageUrl}" alt="${item.title}" loading="lazy">
                </div>
                <div class="content">
                    <h3>${item.title}</h3>
                    <p>${item.description}</p>
                    <span class="tag">${item.category}</span>
                    <div class="price">${item.price}</div>
                </div>
            `;

            container.appendChild(projectCard);
        });

    } catch (error) {
        console.error("Error fetching project data:", error);
        container.innerHTML = `<p class="error">Unable to load catalog. Please try again later.</p>`;
    }
}

// Initialize the fetch when the DOM is fully loaded
document.addEventListener('DOMContentLoaded', fetchGallery);


