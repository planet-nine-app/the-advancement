/**
 * Author Platform JavaScript
 * Handles joan authentication, prof profile management, and sanora book uploads
 */

// Global state
let currentUser = null;
let userKeys = null;
let profileWidget = null;
let bookWidget = null;

// Initialize the platform when page loads
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Author Platform initialized');

    // Check if user has stored session
    const storedUser = localStorage.getItem('authorPlatformUser');
    if (storedUser) {
        try {
            currentUser = JSON.parse(storedUser);
            showUserSections();
            updateUserDisplay();
        } catch (error) {
            console.error('Failed to restore user session:', error);
            localStorage.removeItem('authorPlatformUser');
        }
    }

    // Check current authentication keys
    await checkAuthKeys();

    // Initialize form widgets
    initializeFormWidgets();
});

// Tab switching
function switchTab(tab) {
    // Update tab buttons
    document.querySelectorAll('.auth-tab').forEach(t => t.classList.remove('active'));
    document.querySelector(`[onclick="switchTab('${tab}')"]`).classList.add('active');

    // Update form visibility
    document.querySelectorAll('.auth-form').forEach(f => f.classList.remove('active'));
    document.getElementById(`${tab}-form`).classList.add('active');
}

// Check current authentication keys
async function checkAuthKeys() {
    try {
        const response = await fetch('/api/auth/keys');
        const result = await response.json();

        if (result.success && result.hasKeys) {
            userKeys = { pubKey: result.pubKey };
            console.log('🔑 User keys available:', result.pubKey);
        } else {
            console.log('🔑 No user keys found');
        }
    } catch (error) {
        console.error('Failed to check auth keys:', error);
    }
}

// Initialize form widgets
function initializeFormWidgets() {
    // Create profile form widget
    const profileContainer = document.getElementById('profile-form-container');
    if (profileContainer) {
        // Clear existing form
        profileContainer.innerHTML = '';

        profileWidget = new FormWidget(profileContainer, {
            width: 600,
            height: 350,
            colors: {
                primary: '#4CAF50',
                background: '#ffffff',
                text: '#333333',
                border: '#e0e0e0'
            }
        });

        profileWidget
            .create()
            .addField('name', {
                type: 'text',
                label: 'Author Name',
                placeholder: 'Your author name',
                required: true
            })
            .addField('email', {
                type: 'email',
                label: 'Email',
                placeholder: 'your@email.com',
                required: true
            })
            .addField('bio', {
                type: 'textarea',
                label: 'Bio',
                placeholder: 'Tell readers about yourself'
            })
            .addField('location', {
                type: 'text',
                label: 'Location',
                placeholder: 'Your location'
            })
            .addField('genres', {
                type: 'text',
                label: 'Genres',
                placeholder: 'Fiction, Mystery, Romance (comma-separated)'
            })
            .addSubmitButton('Update Profile')
            .onSubmit(handleProfileUpdateWidget);
    }

    // Create book form widget (using ninefy ebook config)
    const bookContainer = document.getElementById('book-form-container');
    if (bookContainer) {
        // Clear existing form
        bookContainer.innerHTML = '';

        bookWidget = new FormWidget(bookContainer, {
            width: 600,
            height: 400,
            colors: {
                primary: '#4CAF50',
                background: '#ffffff',
                text: '#333333',
                border: '#e0e0e0'
            }
        });

        bookWidget
            .create()
            .addField('title', {
                type: 'text',
                label: 'Title',
                placeholder: 'Product title',
                required: true
            })
            .addField('description', {
                type: 'textarea',
                label: 'Description',
                placeholder: 'Product description',
                required: true
            })
            .addField('price', {
                type: 'number',
                label: 'Price ($)',
                placeholder: '15.99',
                required: true
            })
            .addField('redirectURL', {
                type: 'url',
                label: 'Redirect URL (optional)',
                placeholder: 'https://your-landing-page.com'
            })
            .addSubmitButton('Add Product')
            .onSubmit(handleBookUploadWidget);
    }
}

// Handle login
async function handleLogin(event) {
    event.preventDefault();

    const hash = document.getElementById('login-hash').value.trim();
    if (!hash) {
        showUserStatus('Please enter your account hash', 'error');
        return;
    }

    setLoadingState(true);
    clearUserStatus();

    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ hash })
        });

        const result = await response.json();

        if (result.success) {
            currentUser = result.data;
            localStorage.setItem('authorPlatformUser', JSON.stringify(currentUser));

            showUserStatus('Login successful! Welcome back.', 'success');
            showUserSections();
            updateUserDisplay();

            // Load user profile if available
            await loadUserProfile();
            await loadUserBooks();
        } else {
            showUserStatus(result.error || 'Login failed', 'error');
        }
    } catch (error) {
        console.error('Login error:', error);
        showUserStatus('Login failed. Please check your connection.', 'error');
    } finally {
        setLoadingState(false);
    }
}

// Handle registration
async function handleRegister(event) {
    event.preventDefault();

    const hash = document.getElementById('register-hash').value.trim();
    if (!hash) {
        showUserStatus('Please enter an account hash', 'error');
        return;
    }

    setLoadingState(true);
    clearUserStatus();

    try {
        const response = await fetch('/api/auth/create-user', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ hash })
        });

        const result = await response.json();

        if (result.success) {
            currentUser = result.data;
            localStorage.setItem('authorPlatformUser', JSON.stringify(currentUser));

            showUserStatus('Account created successfully! Welcome to Planet Nine.', 'success');
            showUserSections();
            updateUserDisplay();

            // Switch to profile tab to set up profile
            switchTab('login'); // Reset to login tab view
        } else {
            showUserStatus(result.error || 'Registration failed', 'error');
        }
    } catch (error) {
        console.error('Registration error:', error);
        showUserStatus('Registration failed. Please check your connection.', 'error');
    } finally {
        setLoadingState(false);
    }
}

// Handle profile update from widget
async function handleProfileUpdateWidget(formData) {
    if (!currentUser) {
        showUserStatus('❌ Please login first to update your profile.', 'error');
        return;
    }

    const profileData = {
        name: formData.name,
        email: formData.email,
        bio: formData.bio,
        location: formData.location,
        genres: formData.genres,
        userUUID: currentUser.userUUID || currentUser.uuid
    };

    if (!profileData.name || !profileData.email) {
        showUserStatus('❌ Name and email are required fields for your profile.', 'error');
        return;
    }

    // Show loading feedback
    showUserStatus('⏳ Updating your profile...', 'loading');

    try {
        console.log('📝 Creating/updating profile via prof API:', profileData);

        const response = await fetch('/api/profile/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(profileData)
        });

        const result = await response.json();

        if (result.success) {
            const authorProfile = {
                ...currentUser,
                profile: result.data,
                updatedAt: new Date().toISOString()
            };

            localStorage.setItem('authorProfile', JSON.stringify(authorProfile));

            // Enhanced success feedback with auto-dismiss
            showUserStatus('✅ Profile updated successfully! Your author information has been saved.', 'success');
            updateUserDisplay();

            // Auto-dismiss success message after 3 seconds
            setTimeout(() => {
                clearUserStatus();
            }, 3000);
        } else {
            showUserStatus('❌ ' + (result.error || 'Failed to update profile'), 'error');
        }

    } catch (error) {
        console.error('Profile update error:', error);
        showUserStatus('❌ Failed to update profile. Please check your connection and try again.', 'error');
    }
}

// Handle book upload from widget
async function handleBookUploadWidget(formData) {
    if (!currentUser) {
        showUserStatus('❌ Please login first to create products.', 'error');
        return;
    }

    const bookData = {
        title: formData.title,
        description: formData.description,
        price: parseFloat(formData.price),
        redirectURL: formData.redirectURL || '',
        userUUID: currentUser.userUUID || currentUser.uuid
    };

    if (!bookData.title || !bookData.description || isNaN(bookData.price)) {
        showUserStatus('❌ Please fill in all required fields: title, description, and price.', 'error');
        return;
    }

    // Show loading feedback
    showUserStatus('⏳ Creating your product...', 'loading');

    try {
        console.log('📚 Creating book via sanora API:', bookData);

        const response = await fetch('/api/books/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(bookData)
        });

        const result = await response.json();

        if (result.success) {
            const userBooks = JSON.parse(localStorage.getItem('userBooks') || '[]');
            const newBook = {
                ...result.data,
                id: result.data.productId,
                authorUUID: currentUser.userUUID || currentUser.uuid
            };

            userBooks.push(newBook);
            localStorage.setItem('userBooks', JSON.stringify(userBooks));

            // Enhanced success feedback with emoji and auto-dismiss
            showUserStatus('📚 Product created successfully! "' + bookData.title + '" has been added to your catalog.', 'success');

            // Clear widget form
            if (bookWidget) {
                bookWidget.clear();
            }

            // Refresh books display
            displayUserBooks(userBooks);

            // Auto-dismiss success message after 4 seconds (slightly longer for product creation)
            setTimeout(() => {
                clearUserStatus();
            }, 4000);
        } else {
            showUserStatus('❌ ' + (result.error || 'Failed to create product'), 'error');
        }

    } catch (error) {
        console.error('Book upload error:', error);
        showUserStatus('❌ Failed to create product. Please check your connection and try again.', 'error');
    }
}

// Handle profile update (legacy HTML form - keeping for compatibility)
async function handleProfileUpdate(event) {
    event.preventDefault();

    if (!currentUser) {
        showUserStatus('Please login first', 'error');
        return;
    }

    const profileData = {
        name: document.getElementById('author-name').value.trim(),
        bio: document.getElementById('author-bio').value.trim(),
        location: document.getElementById('author-location').value.trim(),
        genres: document.getElementById('author-genres').value.trim(),
        userUUID: currentUser.userUUID || currentUser.uuid
    };

    if (!profileData.name) {
        showUserStatus('Author name is required', 'error');
        return;
    }

    try {
        console.log('📝 Creating/updating profile via prof API:', profileData);

        // Try to create/update profile in prof service
        const response = await fetch('/api/profile/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(profileData)
        });

        const result = await response.json();

        if (result.success) {
            // Also store locally for UI state
            const authorProfile = {
                ...currentUser,
                profile: result.data,
                updatedAt: new Date().toISOString()
            };

            localStorage.setItem('authorProfile', JSON.stringify(authorProfile));

            showUserStatus('Profile created/updated successfully! ' + (result.note || ''), 'success');
            updateUserDisplay();
        } else {
            showUserStatus(result.error || 'Failed to update profile', 'error');
        }

    } catch (error) {
        console.error('Profile update error:', error);
        showUserStatus('Failed to update profile. Check connection.', 'error');
    }
}

// Handle book upload
async function handleBookUpload(event) {
    event.preventDefault();

    if (!currentUser) {
        showUserStatus('Please login first', 'error');
        return;
    }

    const bookData = {
        title: document.getElementById('book-title').value.trim(),
        description: document.getElementById('book-description').value.trim(),
        price: parseFloat(document.getElementById('book-price').value),
        category: document.getElementById('book-category').value.trim(),
        userUUID: currentUser.userUUID || currentUser.uuid
    };

    if (!bookData.title || !bookData.category || isNaN(bookData.price)) {
        showUserStatus('Please fill in all required book fields', 'error');
        return;
    }

    try {
        console.log('📚 Creating book via sanora API:', bookData);

        // Create book in sanora service
        const response = await fetch('/api/books/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(bookData)
        });

        const result = await response.json();

        if (result.success) {
            // Also store locally for UI state
            const userBooks = JSON.parse(localStorage.getItem('userBooks') || '[]');
            const newBook = {
                ...result.data,
                id: result.data.productId,
                authorUUID: currentUser.userUUID || currentUser.uuid
            };

            userBooks.push(newBook);
            localStorage.setItem('userBooks', JSON.stringify(userBooks));

            showUserStatus('Book created successfully! ' + (result.note || ''), 'success');

            // Clear form
            document.getElementById('book-title').value = '';
            document.getElementById('book-description').value = '';
            document.getElementById('book-price').value = '';
            document.getElementById('book-category').value = '';

            // Refresh books display
            displayUserBooks(userBooks);
        } else {
            showUserStatus(result.error || 'Failed to create book', 'error');
        }

    } catch (error) {
        console.error('Book upload error:', error);
        showUserStatus('Failed to create book. Check connection.', 'error');
    }
}

// Load user profile
async function loadUserProfile() {
    try {
        const storedProfile = localStorage.getItem('authorProfile');
        if (storedProfile) {
            const profile = JSON.parse(storedProfile);
            if (profile.profile) {
                // Load into widget if available
                if (profileWidget) {
                    profileWidget.setData({
                        name: profile.profile.name || '',
                        email: profile.profile.email || '',
                        bio: profile.profile.bio || '',
                        location: profile.profile.location || '',
                        genres: profile.profile.genres || ''
                    });
                }

                // Also update legacy form fields (for compatibility)
                const nameField = document.getElementById('author-name');
                const bioField = document.getElementById('author-bio');
                const locationField = document.getElementById('author-location');
                const genresField = document.getElementById('author-genres');

                if (nameField) nameField.value = profile.profile.name || '';
                if (bioField) bioField.value = profile.profile.bio || '';
                if (locationField) locationField.value = profile.profile.location || '';
                if (genresField) genresField.value = profile.profile.genres || '';
            }
        }
    } catch (error) {
        console.error('Failed to load user profile:', error);
    }
}

// Load user books
async function loadUserBooks() {
    try {
        const userBooks = JSON.parse(localStorage.getItem('userBooks') || '[]');
        displayUserBooks(userBooks);
    } catch (error) {
        console.error('Failed to load user books:', error);
    }
}

// Display user books
function displayUserBooks(books) {
    const booksContainer = document.getElementById('user-books');

    if (!books || books.length === 0) {
        booksContainer.innerHTML = '<p>No books yet. Add your first book above!</p>';
        return;
    }

    const booksHTML = books.map(book => `
        <div class="book-item">
            <h4>${book.title}</h4>
            <p>${book.description}</p>
            <p><strong>Price:</strong> $${book.price.toFixed(2)} | <strong>Category:</strong> ${book.category}</p>
            <p><small>Added: ${new Date(book.createdAt).toLocaleDateString()}</small></p>
        </div>
    `).join('');

    booksContainer.innerHTML = booksHTML;
}

// Show/hide user sections and collapse auth
function showUserSections() {
    // Collapse the auth section
    const authSection = document.getElementById('auth-section');
    const mainContent = document.getElementById('main-content');
    const loggedInUser = document.getElementById('logged-in-user');

    authSection.classList.add('collapsed');
    mainContent.classList.add('show');

    // Update logged in user display
    if (currentUser) {
        const displayName = currentUser.userUUID ? currentUser.userUUID.substring(0, 8) + '...' : 'User';
        loggedInUser.textContent = displayName;
    }
}

// Update user display
function updateUserDisplay() {
    const userDetails = document.getElementById('current-user-details');
    if (currentUser) {
        const uuid = currentUser.userUUID || currentUser.uuid || 'Unknown';
        const pubKey = userKeys ? userKeys.pubKey.substring(0, 16) + '...' : 'Not available';
        userDetails.innerHTML = `
            <strong>UUID:</strong> ${uuid}<br>
            <strong>Public Key:</strong> ${pubKey}<br>
            <strong>Status:</strong> Authenticated
        `;
    } else {
        userDetails.textContent = 'Not logged in';
    }
}

// Show user status message
function showUserStatus(message, type) {
    const statusDiv = document.getElementById('user-status');
    statusDiv.className = `user-status ${type}`;
    statusDiv.textContent = message;
    statusDiv.style.display = 'block';
}

// Clear user status
function clearUserStatus() {
    const statusDiv = document.getElementById('user-status');
    statusDiv.style.display = 'none';
}

// Set loading state
function setLoadingState(loading) {
    const loadingDiv = document.getElementById('auth-loading');
    const loginBtn = document.getElementById('login-btn');
    const registerBtn = document.getElementById('register-btn');

    if (loading) {
        loadingDiv.classList.add('show');
        loginBtn.disabled = true;
        registerBtn.disabled = true;
    } else {
        loadingDiv.classList.remove('show');
        loginBtn.disabled = false;
        registerBtn.disabled = false;
    }
}

// Logout function
function logout() {
    currentUser = null;
    userKeys = null;
    localStorage.removeItem('authorPlatformUser');
    localStorage.removeItem('authorProfile');
    localStorage.removeItem('userBooks');

    // Expand auth section and hide main content
    const authSection = document.getElementById('auth-section');
    const mainContent = document.getElementById('main-content');

    authSection.classList.remove('collapsed');
    mainContent.classList.remove('show');

    // Clear forms
    document.getElementById('login-hash').value = '';
    document.getElementById('register-hash').value = '';

    // Reset display
    updateUserDisplay();
    clearUserStatus();

    showUserStatus('Logged out successfully', 'success');
}

// Export for global access
window.switchTab = switchTab;
window.handleLogin = handleLogin;
window.handleRegister = handleRegister;
window.handleProfileUpdate = handleProfileUpdate;
window.handleBookUpload = handleBookUpload;
window.logout = logout;