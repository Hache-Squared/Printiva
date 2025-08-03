using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarioColores
    {
        Task<IEnumerable<InventarioColor>> ObtenerTodos();
        Task Crear(InventarioColor color);
        Task<InventarioColor?> ObtenerPorId(int id);
        Task Actualizar(InventarioColor color);
        Task Borrar(int id);
    }

    public class RepositorioInventarioColores : IRepositorioInventarioColores
    {
        private readonly string connectionString;

        public RepositorioInventarioColores(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<InventarioColor>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<InventarioColor>(
                @"
                    SELECT * FROM TblInventariosColores
                "
            );
        }

        public async Task Crear(InventarioColor color)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventariosColores (Nombre, Abreviatura)
                    VALUES (@Nombre, @Abreviatura);

                    SELECT SCOPE_IDENTITY();
                ",
                color
            );

            color.InventarioColorId = id;
        }

        public async Task<InventarioColor?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<InventarioColor>(
                @"
                    SELECT * FROM TblInventariosColores WHERE InventarioColorId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(InventarioColor color)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioColor>(
                @"
                    UPDATE TblInventariosColores SET Nombre = @Nombre, Abreviatura = @Abreviatura
                    WHERE InventarioColorId = @InventarioColorId;
                ",
                color
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioColor>(
                @"
                    DELETE TblInventariosColores WHERE InventarioColorId = @id;
                ",
                new { id }
            );
        }
    }
}
