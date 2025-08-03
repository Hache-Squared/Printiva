using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarios
    {
        Task<IEnumerable<Inventario>> ObtenerTodos();
        Task Crear(Inventario inventario);
        Task<Inventario?> ObtenerPorId(int id);
        Task Actualizar(Inventario inventario);
        Task Borrar(int id);
    }

    public class RepositorioInventarios : IRepositorioInventarios
    {
        private readonly string connectionString;

        public RepositorioInventarios(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Inventario>> ObtenerTodos()
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Inventario>(
                @"
                    SELECT * FROM TblInventarios ORDER BY FechaCreacion DESC, InventarioId DESC
                "
            );
        }

        public async Task Crear(Inventario inventario)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventarios (InventarioMarcaId, InventarioTipoId, InventarioNombreId, InventarioColorId, Cantidad, InventarioUnidadId, FechaCreacion)
                    VALUES (@InventarioMarcaId, @InventarioTipoId, @InventarioNombreId, @InventarioColorId, @Cantidad, @InventarioUnidadId, @FechaCreacion);

                    SELECT SCOPE_IDENTITY();
                ",
                inventario
            );

            inventario.InventarioId = id;
        }

        public async Task<Inventario?> ObtenerPorId(int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    SELECT * FROM TblInventarios WHERE InventarioId = @Id
                ",
                new { id }
            );
        }

        public async Task Actualizar(Inventario inventario)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    UPDATE TblInventarios SET InventarioMarcaId = @InventarioMarcaId, InventarioTipoId = @InventarioTipoId, InventarioNombreId = @InventarioNombreId, InventarioColorId = @InventarioColorId, Cantidad = @Cantidad, InventarioUnidadId = @InventarioUnidadId, FechaCreacion = @FechaCreacion
                    WHERE InventarioId = @InventarioId;
                ",
                inventario
            );
        }

        public async Task Borrar(int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                @"
                    DELETE TblInventarios WHERE InventarioId = @id;
                ",
                new { id }
            );
        }
    }
}
