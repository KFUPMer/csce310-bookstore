import '../models/book.dart';

/// The same 15 books as database/mongodb/books.json.
///
/// PREVIEW ONLY: used to judge the look of the catalog before book-service
/// exists. Removed in milestone M4, when the screen loads books from the API.
const mockBooks = <Book>[
  Book(id: '1', title: 'Clean Code', author: 'Robert C. Martin', price: 40, copiesAvailable: 4),
  Book(id: '2', title: 'The Pragmatic Programmer', author: 'Andrew Hunt and David Thomas', price: 45, copiesAvailable: 5),
  Book(id: '3', title: 'Database System Concepts', author: 'Abraham Silberschatz', price: 55, copiesAvailable: 2),
  Book(id: '4', title: 'Fundamentals of Database Systems', author: 'Ramez Elmasri', price: 60, copiesAvailable: 3),
  Book(id: '5', title: 'Java Concurrency in Practice', author: 'Brian Goetz', price: 80, copiesAvailable: 6),
  Book(id: '6', title: 'Effective Java', author: 'Joshua Bloch', price: 50, copiesAvailable: 4),
  Book(id: '7', title: 'Head First Java', author: 'Kathy Sierra and Bert Bates', price: 35, copiesAvailable: 7),
  Book(id: '8', title: 'Design Patterns', author: 'Erich Gamma', price: 65, copiesAvailable: 2),
  Book(id: '9', title: 'Refactoring', author: 'Martin Fowler', price: 48, copiesAvailable: 3),
  Book(id: '10', title: 'Introduction to Algorithms', author: 'Thomas H. Cormen', price: 90, copiesAvailable: 2),
  Book(id: '11', title: 'Computer Networking: A Top-Down Approach', author: 'James Kurose and Keith Ross', price: 70, copiesAvailable: 3),
  Book(id: '12', title: 'Operating System Concepts', author: 'Abraham Silberschatz', price: 75, copiesAvailable: 1),
  Book(id: '13', title: 'Fluent Python', author: 'Luciano Ramalho', price: 52, copiesAvailable: 4),
  Book(id: '14', title: 'Flask Web Development', author: 'Miguel Grinberg', price: 38, copiesAvailable: 5),
  Book(id: '15', title: 'MongoDB: The Definitive Guide', author: 'Shannon Bradshaw', price: 44, copiesAvailable: 0),
];
