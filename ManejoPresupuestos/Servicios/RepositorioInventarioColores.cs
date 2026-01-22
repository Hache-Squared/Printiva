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
        Task Actualizar(int usuarioId, InventarioColor color);
        Task Borrar(int usuarioId, int id);
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
                    SELECT * 
                    FROM TblInventariosColores i
                    WHERE i.EstaActivo = 1
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

        public async Task Actualizar(int usuarioId, InventarioColor color)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioColor>(
                "procAlteraInventariosColores",
                new
                {
                    elementoAlterarId = color.InventarioColorId,
                    nombre = color.Nombre,
                    abreviatura = color.Abreviatura,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<InventarioColor>(
                "procAlteraInventariosColores",
                new
                {
                    elementoAlterarId = id,
                    nombre = "Color eliminado",
                    abreviatura = "Color eliminado",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
